/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDMeaningfulDataTriggerHandler
* @Why   : Handles all the customization involved on Meaningful Data object.
* @When  : 06-APR-2017
* @Where : From Meaningful_Data_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID             Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Admin                 06-APR-2017             Work ID / Case ID            Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*    Admin                 27-MAY-2020             #123/CHARM-2729              Prevented multiple updates of the ticket 
                                                                                in the same transaction.
*  --------------------------------------------------------------------------------------------------------------------------------------
*    oivan                 24-JUN-2020             #143 (CHARM-2801)Create MDC Ticket on Insert of Record       Added createMDC().
*  --------------------------------------------------------------------------------------------------------------------------------------
*    oivan                 06-JAN-2021             TWD Upgrade issue            Added logic from disabled WF rule in beforeInsert
*  --------------------------------------------------------------------------------------------------------------------------------------
*    OBriceno                 15-Feb-2020           MDC Refactor                  createMDCTicket method
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE              29-JUN-2026             CHaRM R9.0/IPDR 409          Added configurable MDC prevention validation to generate MDC 
 * 																				records only for eligible Meaningful Data based on the parent 
 * 																				Ticket creation time and configured prevention interval.
 * --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDMeaningfulDataTriggerHandler extends TriggerHandler {
    public static boolean executeOnceFlag = false;
/**
* @Method       : beforeInsert
* @Invoke       : Events from TriggerHandler before insert
* @Description  : To handle all the logic in before insert event
* @Return       : N/A
* @Params       : N/A
**/
    public override void beforeInsert() {
        //TWD Upgrade issue start.
        List<Meaningful_Data__c> meaningfulDataList = (List<Meaningful_Data__c>) Trigger.new;
        for (Meaningful_Data__c meaningfulData: meaningfulDataList) {
            
            if ((meaningfulData.Meaningful_Data_Category__c != null && meaningfulData.Meaningful_Data_Category__c != '')
                || (meaningfulData.Mean__c  != null && meaningfulData.Mean__c  != '')
                || (meaningfulData.Meaningful_Data_Answers__c != null && meaningfulData.Meaningful_Data_Answers__c != '')) {
                    meaningfulData.Meaningful_Data_Details__c = 'Meaningful Data Category: ' + '- ' + overwriteNullWithEmpty(meaningfulData.Meaningful_Data_Category__c) + '\n' +
                                                                'Meaningful Data Question: ' + '- ' + overwriteNullWithEmpty(meaningfulData.Mean__c) + '\n' + 
                                                                'Meaningful Data Answer: ' + '- ' + overwriteNullWithEmpty(meaningfulData.Meaningful_Data_Answers__c);
            }    
        }
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }
    
/**
* @Method       : afterInsert
* @Invoke       : Events from TriggerHandler after insert
* @Description  : To handle all the logic in after insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit(); // Commented for 354
        
        if(!executeOnceFlag) {
            executeOnceFlag = true;
            updateTicketLastModifiedDate();
            ADDTranslations.ChildObjectTranslations();            
			//#143 (CHARM-2801) start. Check conditions and create MDC ticket on Insert
			//#143 (CHARM-2801) end.
            Map<Id, Meaningful_Data__c> MeaningfulDataMap = new Map<Id, Meaningful_Data__c>((List<Meaningful_Data__c>)Trigger.new);
            ADD_App_Settings__c addApp = ADD_App_Settings__c.getInstance();
            /*CHaRM R9.0/IPDR-409 : Fallback switch to immediately use the existing MDC generation logic.
                This feature was introduced as a safeguard in case high-volume Meaningful Data
                loads from CMSNext cause issues with the new MDC prevention logic.*/
            if (addApp != null && addApp.Enable_MDC_Prevention_Logic__c) {
                createMDCTicket(MeaningfulDataMap);
                return;
            }
            Set<Id> ticketIds = new Set<Id>();
            for (Meaningful_Data__c md : (List<Meaningful_Data__c>) Trigger.new) {
                if (md.Compliant__c != null) {
                    ticketIds.add(md.Compliant__c);
                }
            }
            
            if (!ticketIds.isEmpty()) {
                Map<Id, CMPL123CME__Complaint__c> ticketMap =
                    new Map<Id, CMPL123CME__Complaint__c>(
                        [SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds] );
                Map<Id,Meaningful_Data__c> filteredMeaningfulDataMap = new Map<Id,Meaningful_Data__c>();
                for (Meaningful_Data__c mdRecord : (List<Meaningful_Data__c>)Trigger.new) {
                    CMPL123CME__Complaint__c ticket = ticketMap.get(mdRecord.Compliant__c);
                    Integer minutesToAdd = Integer.valueOf(addApp.MDC_Generation_Prevention_Minutes__c);
                    /*CHaRM R9.0/IPDR-409 : Prevent MDC generation for Meaningful Data added shortly after ticket creation.
                    MDC will only be generated once the configured prevention window has elapsed.
                    This avoids creating MDCs for newly created tickets. After the configured
                    time threshold is reached, MDC generation resumes as normal.*/
                    if (System.now() > ticket.CreatedDate.addMinutes(minutesToAdd)) {
                        filteredMeaningfulDataMap.put(mdRecord.Id, mdRecord);
                    }
                }
                if(!filteredMeaningfulDataMap.isEmpty()){
                    createMDCTicket(filteredMeaningfulDataMap);
                }
            }
        }
    }

/**
* @Method       : beforeUpdate
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/
    public override void beforeUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }
    
/**
* @Method       : afterUpdate
* @Invoke       : Events from TriggerHandler after update
* @Description  : To handle all the logic in after update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit(); // Commented for 354
        
        if(!executeOnceFlag) {
            executeOnceFlag = true;
            updateTicketLastModifiedDate();
            ADDTranslations.ChildObjectTranslations();
        }
    }

/**
* @Method       : beforeDelete
* @Invoke       : Events from TriggerHandler before delete
* @Description  : To handle all the logic in before delete event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }  
    
      /**
* @Method       : updateTicketLastModifiedDate
* @Invoke       : Events from TriggerHandler after insert / update
* @Description  : To update parent record "Last Modified Date/Time" field based on child record's parent Id collection
* @Return       : N/A
* @Params       : Trigger
**/ 
    private static void updateTicketLastModifiedDate(){
        // Defect #123/CHARM-2729: prevent multiple updates of the ticket in the same transaction
        if(!UpdateParentUtility.isTicketUpdated || !ComplaintTriggerHandler.isTicketInserting){
            Set<Id> setComplaintIdToUpdate = new Set<Id>();
            for(Meaningful_Data__c objRecord : (List<Meaningful_Data__c>)Trigger.new){
                if(objRecord.Compliant__c != null)
                    setComplaintIdToUpdate.add(objRecord.Compliant__c);              
            }
            if(setComplaintIdToUpdate.size() > 0){
                UpdateParentUtility.ticketTriggerPreventFlag = true;
                UpdateParentUtility.updateparent(setComplaintIdToUpdate);
                // Defect #123/CHARM-2729: disable ticket trigger logic only for UpdateParentUtility.updateparent method execution 
                UpdateParentUtility.ticketTriggerPreventFlag = false;     
            }
        }       
    }
	    /**
    * @Method       : createMDCTicket
    * @Invoke       : Create MDC Ticket if record match conditions on Insert. #143 (CHARM-2801)
    * @Description  : Check conditions and create MDC Ticket if needed
    * @Return       : N/A
    * @Params       : Map<Id,Meaningful_Data__c>
    **/
    public void createMDCTicket(Map<Id,Meaningful_Data__c> meaningfulDataNewMap) {
	
        Map <Id, Meaningful_Data__c> meaningfulDataMatchCondition = new Map <Id, Meaningful_Data__c>();
        Map <Id, Meaningful_Data__c> meaningfulDataMatchConditionMedEval = new Map <Id, Meaningful_Data__c>();
        Set <Id> ticketIds = new Set <Id>();
        for (Meaningful_Data__c meaningfulData: meaningfulDataNewMap.values()) {
            ticketIds.add(meaningfulData.Compliant__c);
        }
        
        // refactor
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);
        for (Meaningful_Data__c meaningfulData: meaningfulDataNewMap.values()) {
            if (meaningfulData.Meaningful_Data_Answers__c  != null) {
                Map<String, Boolean> boolMap = ticketMap.get(meaningfulData.Compliant__c); 
                //@Juneid @12 FEB , 2021, Using MDCTicketUtil Static Variable
                if (boolMap.get('hasProdEval')) { 
                    meaningfulDataMatchCondition.put(meaningfulData.Id, meaningfulData);
                } //@Juneid @12 FEB , 2021, Using MDCTicketUtil Static Variable
                if (boolMap.get('hasMedEval')) {
                    meaningfulDataMatchConditionMedEval.put(meaningfulData.Id, meaningfulData);
                }                    
            }
        }
        
        if (meaningfulDataMatchCondition.size() > 0) {
            MDCTicketUtil.createMDC('Meaningful Data Change for Evaluator/Investigator', meaningfulDataMatchCondition, 'Compliant__c', 'Ticket_Number__c', 'meaningful_data_answers__c', TRUE);
        }
        if (meaningfulDataMatchConditionMedEval.size() > 0) {
            MDCTicketUtil.createMDC('Meaningful Data Change for med evaluator', meaningfulDataMatchConditionMedEval, 'Compliant__c', 'Ticket_Number__c', 'meaningful_data_answers__c', TRUE);
        }
    }
    /**
* @Method       : overwriteNullWithEmpty
* @Invoke       : From ADDMeaningfulDataTriggerHandler class
* @Description  : overwrite Null With Empty string
* @Return       : String 
* @Params       : String value
**/      
    public String overwriteNullWithEmpty(String value) {
        if (value == null) {
            return '';
        } 
        return value;
    }
}