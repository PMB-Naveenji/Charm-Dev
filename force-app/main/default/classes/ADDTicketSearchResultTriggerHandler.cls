/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDTicketSearchResultTriggerHandler  
* @Why   : Handles all the customization involved on Ticket Search Result object
* @When  : 06-APR-2017
* @Where : From Ticket_Review_AuditTrigger trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    06-APR-2017            Work ID / Case ID          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   dskak                    20-FEB-2020            Defect #11 (CHARM-2016)    Edited.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rslob                    21-FEB-2020            Defect #11 (CHARM-2016)    Edited.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit                 Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit                 Updated Jira reference with reference from Defect Tracker. 
*                                                                              Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    06-JAN-2021            TWD Upgrade issue          Added Logic from WF rules is moved to apex
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Juneid                   18-Sep-2-21           MIR Release                  Added Logic for MIR Submisiosn Information
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDTicketSearchResultTriggerHandler extends TriggerHandler {

    private Static Boolean isInsertAndUpdate = false;
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
   public override void beforeInsert() {
        isInsertAndUpdate = true;
        //  Added by dskak to fix external Defect #11 (CHARM-2016) defect
        populateSubmissionInfoField();
        //  End of the fix
        //TWD Upgrade issue start
        //WF: Autoset Registration Number
        Set <Id> ticketIds = new Set <Id>();
        List <Ticket_Search_Result__c> ticketSearches = (List <Ticket_Search_Result__c>) Trigger.New;
        for (Ticket_Search_Result__c ticketSearch: ticketSearches) {
            ticketIds.add(ticketSearch.Ticket__c);
            //WF: Set Ticket Review Status Date 
            if (ticketSearch.Ticket_Review_Status__c != null) {
                ticketSearch.Ticket_Review_Status_Date__c = date.today();
            }
        }
        Map <Id, CMPL123CME__Complaint__c> ticketById = new Map <Id, CMPL123CME__Complaint__c>([SELECT CMSNext_Ticket_Number__c, RecordType.DeveloperName, Service_Type__c 
                                                                                                FROM CMPL123CME__Complaint__c 
                                                                                                WHERE Id in: ticketIds]);
        for (Ticket_Search_Result__c ticketSearch: ticketSearches) {
            if (ticketSearch.Ticket__c != null && ticketById.containsKey(ticketSearch.Ticket__c) && ticketById.get(ticketSearch.Ticket__c).CMSNext_Ticket_Number__c != null){
                if (ticketById.get(ticketSearch.Ticket__c).RecordType.DeveloperName == 'Complaint') {
                   ticketSearch.Registration_Number__c = ticketById.get(ticketSearch.Ticket__c).CMSNext_Ticket_Number__c +
                                             '(' + ticketById.get(ticketSearch.Ticket__c).RecordType.DeveloperName + ')';
                } else if (ticketById.get(ticketSearch.Ticket__c).RecordType.DeveloperName == 'Inquiry') {
                    ticketSearch.Registration_Number__c = ticketById.get(ticketSearch.Ticket__c).CMSNext_Ticket_Number__c +
                                             '(' + ticketById.get(ticketSearch.Ticket__c).RecordType.DeveloperName + ')';
                } else if (ticketById.get(ticketSearch.Ticket__c).RecordType.DeveloperName == 'Service') {
                    ticketSearch.Registration_Number__c = ticketById.get(ticketSearch.Ticket__c).CMSNext_Ticket_Number__c +
                                             '(' + ticketById.get(ticketSearch.Ticket__c).Service_Type__c + ' ' + 
                                              ticketById.get(ticketSearch.Ticket__c).RecordType.DeveloperName + ')';
                }
                
            }
        }
        //TWD Upgrade issue end
    }
    //Commented for Ticket Search records created by Report SnapShot.

    /**
    * @Method       : afterInsert
    * @Invoke       : Events from TriggerHandler after insert
    * @Description  : To handle all the logic in after insert event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterInsert() {
        isInsertAndUpdate = true;
        //populateSubmissionInfoField();
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /**
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void beforeUpdate() {
        //TWD Upgrade issue start
        //WF: Set Ticket Review Status Date 
        List <Ticket_Search_Result__c> ticketSearches = (List <Ticket_Search_Result__c>) Trigger.New;
        Map <Id, Ticket_Search_Result__c> oldTicketSearchById = (Map <Id, Ticket_Search_Result__c>) Trigger.OldMap;
        for (Ticket_Search_Result__c ticketSearch: ticketSearches) {
            if (ticketSearch.Ticket_Review_Status__c != oldTicketSearchById.get(ticketSearch.Id).Ticket_Review_Status__c) {
                ticketSearch.Ticket_Review_Status_Date__c = date.today();
            }
        }
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
        if (!isInsertAndUpdate) {
            CMPL123.AuditHandler.handleAudit();
        }
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
        if (!isInsertAndUpdate) {
            CMPL123.AuditHandler.handleAudit();
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
    * @Method       : afterDelete
    * @Invoke       : Events from TriggerHandler after delete
    * @Description  : To handle all the logic in after delete event
    * @Return       : N/A
    * @Params       : N/A
    **/
    public override void afterDelete() {
    }

    /**
    * @Method       : populateSubmissionInfoField by dskak
    * @Invoke       : called from beforeInsert method
    * @Description  : To populate Submission_Information__c as required in Defect #11 (CHARM-2016) defect
    * @Return       : N/A
    * @Params       : N/A
    **/
    private static void populateSubmissionInfoField() {
        Map<Id, Ticket_Search_Result__c> complaintIdTSR = new Map<Id, Ticket_Search_Result__c>();

        for (Ticket_Search_Result__c tsr : (List<Ticket_Search_Result__c>) Trigger.new) {
            complaintIdTSR.put(tsr.Ticket__c, tsr);
        }

        List<CMPL123CME__Complaint__c> complaints = [
                SELECT Id, (
                        SELECT Id, RecordType.Name, CMPL123CME__CMPL123_WF_Status__c, Classification__c
                        FROM CMPL123CME__EMDR__r
                        ORDER BY CreatedDate
                ), (
                        SELECT Id, CMPL123CME__Type_of_Report__c, CMPL123_WF_Status__c
                        FROM CMPL123CME__MEDDEV__r
                        ORDER BY CreatedDate
                ),
                (
                        SELECT Id, CMPL123CME__Type_Of_Report__c, CMPL123_WF_Status__c
                        FROM CMPL123CME__EU_MIR__r
                        ORDER BY CreatedDate
                )
                FROM CMPL123CME__Complaint__c
                WHERE Id IN :complaintIdTSR.keySet()
        ];
        
        for (CMPL123CME__Complaint__c complaint : complaints) {
            //Duplication fix BEGIN
            complaintIdTSR.get(complaint.Id).Submission_Information__c = '';
            //Duplication fix END
          for (CMPL123CME__MEDDEV__c meddev : complaint.CMPL123CME__MEDDEV__r) {
                complaintIdTSR.get(complaint.Id).Submission_Information__c +=
                        (meddev.CMPL123CME__Type_of_Report__c != null ? meddev.CMPL123CME__Type_of_Report__c + '~' : '') +
                                +'MDI' + '~' + meddev.CMPL123_WF_Status__c + '\r\n';
            }
            for (CMPL123CME__EMDR__c emdr : complaint.CMPL123CME__EMDR__r) {
                complaintIdTSR.get(complaint.Id).Submission_Information__c += emdr.RecordType.Name + '~' + 'eMDR' + '~'
                        + emdr.CMPL123CME__CMPL123_WF_Status__c +
                        (emdr.Classification__c != null ? '~' + emdr.Classification__c : '') + '\r\n';
            }
            
            for(CMPL123CME__EU_MIR__c euMirRecord : complaint.CMPL123CME__EU_MIR__r){
                complaintIdTSR.get(complaint.Id).Submission_Information__c += (euMirRecord.CMPL123CME__Type_of_Report__c != null ? euMirRecord.CMPL123CME__Type_of_Report__c+'~' : '') +
                +'EUMIR'+ '~'+euMirRecord.CMPL123_WF_Status__c+'  \r\n';
            }
        }

        for (Ticket_Search_Result__c tsr : (List<Ticket_Search_Result__c>) Trigger.new) {
            tsr.Submission_Information__c = complaintIdTSR.get(tsr.Ticket__c).Submission_Information__c;
        }
       
        
    }
}