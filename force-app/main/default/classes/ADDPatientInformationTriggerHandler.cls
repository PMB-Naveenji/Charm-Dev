/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDPatientInformationTriggerHandler.
* @Why   : Handles all the customization involved on Patient Information object.
* @When  : 06-APR-2017.
* @Where : From Patient_Information_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer           Date                  Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin               06-APR-2017           Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan               23-JUN-2020           #124/CHARM-2724               Added createMDC() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih               11-AUG-2020           Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* OBriceno            15-Feb-2020           MDC Refactor                  createMDCTicket method
* --------------------------------------------------------------------------------------------------------------------------------------
*  CHaRM COE         29-JUN-2026             CHaRM R9.0/IPDR 409        Added configurable MDC prevention validation to generate MDC 
 * 																		records only for eligible Patient Information based on the parent 
 * 																		Ticket creation time and configured prevention interval.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDPatientInformationTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert.
    * @Description  : To handle all the logic in before insert event.
    * @Invoke       : From Patient_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeInsert() {
        //code which invokes 123Compliance platform audit and workflow code

    }

    /*
    * @Method       : afterInsert.
    * @Description  : To handle all the logic in after insert event.
    * @Invoke       : From Patient_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterInsert() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        ADDTranslations.ChildObjectTranslations();
        //#124(CHARM-2724) start. Check conditions and create MDC ticket on Insert
        //#124(CHARM-2724) end.
        Map<Id, Patient_Information__c> PatientInfoMap = new Map<Id, Patient_Information__c>((List<Patient_Information__c>)Trigger.new);
        ADD_App_Settings__c addApp = ADD_App_Settings__c.getInstance();
        /*CHaRM R9.0/IPDR-409 : Fallback switch to immediately use the existing MDC generation logic.
          This feature was introduced as a safeguard in case high-volume Patient Information
          loads from CMSNext cause issues with the new MDC prevention logic.*/
        if (addApp != null && addApp.Enable_MDC_Prevention_Logic__c) {
            createMDCTicket(PatientInfoMap);
            return;
        }
        Set<Id> ticketIds = new Set<Id>();
        for (Patient_Information__c pi : (List<Patient_Information__c>) Trigger.new) {
            if (pi.Related_Ticket_Id__c != null) {
                ticketIds.add(pi.Related_Ticket_Id__c);
            }
        }
        
        if (!ticketIds.isEmpty()) {
            Map<Id, CMPL123CME__Complaint__c> ticketMap =
                new Map<Id, CMPL123CME__Complaint__c>(
                    [SELECT Id, CreatedDate FROM CMPL123CME__Complaint__c WHERE Id IN :ticketIds] );
            Map<Id,Patient_Information__c> filteredpatientInfoMap = new Map<Id,Patient_Information__c>();
            for (Patient_Information__c piRecord : (List<Patient_Information__c>)Trigger.new) {
                CMPL123CME__Complaint__c ticket = ticketMap.get(piRecord.Related_Ticket_Id__c);
                Integer minutesToAdd = Integer.valueOf(addApp.MDC_Generation_Prevention_Minutes__c);
                /*CHaRM R9.0/IPDR-409 : Prevent MDC generation for Patient Information added shortly after ticket creation.
                    MDC will only be generated once the configured prevention window has elapsed.
                    This avoids creating MDCs for newly created tickets. After the configured
                    time threshold is reached, MDC generation resumes as normal.*/
                if (System.now() > ticket.CreatedDate.addMinutes(minutesToAdd)) {
                    filteredpatientInfoMap.put(piRecord.Id, piRecord);
                }
            }
            if(!filteredpatientInfoMap.isEmpty()){
                createMDCTicket(filteredpatientInfoMap);
            }
        }
    }

    /*
    * @Method       : beforeUpdate.
    * @Description  : To handle all the logic in before update event.
    * @Invoke       : From Patient_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeUpdate() {
       CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : afterUpdate.
    * @Description  : To handle all the logic in after update event.
    * @Invoke       : From Patient_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();

        ADDTranslations.ChildObjectTranslations();
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From Patient_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /*
    * @Method       : beforeDelete.
    * @Description  : To handle all the logic in before delete event.
    * @Invoke       : From Patient_Information_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public override void afterDelete() {
    }

    /*
    * @Method       : createMDCTicket.
    * @Description  : Check conditions and create MDC Ticket if needed.
    * @Invoke       : Create MDC Ticket if record match conditions on Insert. #124(CHARM-2724).
    * @Return       : N/A.
    * @Params       : Map<Id,Patient_Information__c>
    */
    public void createMDCTicket(Map<Id,Patient_Information__c> patientInfoNewMap) {
        Map <Id, Patient_Information__c> patientInfoMatchCondition = new Map <Id, Patient_Information__c>();
        Set <Id> ticketIds = new Set <Id>();
        for (Patient_Information__c patientInfo: patientInfoNewMap.values()) {
            ticketIds.add(patientInfo.Parent_Ticket_Id__c);
        }
          
        
        Map<Id, Map<String, Boolean>> ticketMap = MDCTicketUtil.getParentTicketDetails(ticketIds);  

        for (Patient_Information__c patientInfo: patientInfoNewMap.values()) {
            Map<String, Boolean> boolMap = ticketMap.get(patientInfo.Parent_Ticket_Id__c); 
            if ((patientInfo.Patient_Information__c != null || 
                 patientInfo.Patient_Information_Translated__c != null || 
                 patientInfo.External_Id__c != null) && boolMap.get('hasMedEval')) {
                    patientInfoMatchCondition.put(patientInfo.Id, patientInfo);
            }
        }
        if (patientInfoMatchCondition.size() > 0) {
            MDCTicketUtil.createMDC('Patient Information Change', patientInfoMatchCondition, 'Parent_Ticket_Id__c', 'Registration_Number__c', 'patient_information__c', TRUE);
        }
    }
}