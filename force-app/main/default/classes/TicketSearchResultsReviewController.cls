/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketSearchResultsReviewController.
* @Why   : This class is used to review and update Ticket_Search_Result__c records.
* @When  : 20-MAR-2019.
* @Where : From TicketSearchResultsReview page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    20-MAR-2019            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    21-MAR-2019            Work ID / Case ID                 Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    22-MAR-2019            Work ID / Case ID                 Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    26-APR-2019            Work ID / Case ID                 Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                        Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    07-SEP-2020            Code Audit                        Removed empty If condition.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    16-OCT-2020            HC #40/CHARM-3336                 Uncommented logic which was commented to resolve 
*                                                                                   #870, #871 and #909 defects to match Business' 
*                                                                                   expectations
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    20-OCT-2020            HC #40/CHARM-3336                 Added Record Type checking for parent ticket
*                                                                                   reopening logic.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class TicketSearchResultsReviewController{

    // Final data to be saved
    public Transient String strJSONticketSearchResults {get; set;}

    // ticketReview Id from page param
    private string ticketReviewId;

    // If any error
    public Boolean isError {get; private set;}

    public static Boolean isRelatedwithMalfunction = false;

    /*
    * @Method       : TicketSearchResultsReviewController.
    * @Description  : Constructor to call validator method.
    * @Invoke       : Constructor.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public TicketSearchResultsReviewController(){
        getTicketSearchResults();
    }

    /*
    * @Method       : getTicketSearchResults.
    * @Description  : This method is used to validate the ticket review record.
    * @Invoke       : From constructor.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public pagereference getTicketSearchResults(){
        ticketReviewId = ApexPages.currentPage().getParameters().get('TRID');
        Boolean isRecordFound = false;
        String strStoreBatchIds = '';
        for(Ticket_Search_Result__c objTicketSearchResult : [SELECT Id, Ticket_Review__r.Status__c, Ticket_Review__r.Pending_Batch_Jobs__c FROM Ticket_Search_Result__c WHERE Ticket_Review__c =: ticketReviewId LIMIT 1]){
            if(objTicketSearchResult.Ticket_Review__r.Status__c == 'Inactive'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Review_Cannot_Display_Search_Results));
                isError = true;
                return null;
            }else{
                if(String.isNotBlank(objTicketSearchResult.Ticket_Review__r.Pending_Batch_Jobs__c)){
                    strStoreBatchIds = objTicketSearchResult.Ticket_Review__r.Pending_Batch_Jobs__c;
                }
                isRecordFound = true;
            }
        }

        if(String.isNotBlank(strStoreBatchIds)){
            Set<String> setBatchIds = New Set<String>(strStoreBatchIds.split(','));
            Set<String> setBatchStatuses = New Set<String>{'Holding','Queued','Preparing','Processing'};
                List<AsyncApexJob> lstAsyncApexJobs = [SELECT Id FROM AsyncApexJob WHERE Id IN: setBatchIds AND status IN: setBatchStatuses AND JobType = 'BatchApex'];
            if (lstAsyncApexJobs.size() != 0) { // Def HC #40/CHARM-3336: removed wrong condition (lstAsyncApexJobs - always not null)
                isError = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm,Label.Ticket_Search_Please_wait));
                return null;
            }
        }

        if(!isRecordFound){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,Label.Ticket_Review_No_Search_Results));
            isError = true;
            return null;
        }
        return null;
    }

    /*
    * @Method       : processTicketSearchResults.
    * @Description  : This method is used to update Ticket_Search_Result__c Records and also to update reated Med Evals.
    * @Invoke       : From TicketSearchResultsReview page, Action Function.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public pagereference processTicketSearchResults(){
        List<Ticket_Search_Result__c> lstTicketSearchResults = (List<Ticket_Search_Result__c>) JSON.deserialize(strJSONticketSearchResults, List<Ticket_Search_Result__c>.class);
        String strFieldActionNumber = '';
        String strSearchFrequency = '';
        String recordTypeName = '';
        for(Ticket_Search_Result__c objTicketSearchResult : [SELECT Id, Ticket_Review__r.RecordType.Name,  Ticket_Review__r.Field_Action_Number__c, Ticket_Review__r.Search_Frequency__c FROM Ticket_Search_Result__c WHERE Ticket_Review__c =: ticketReviewId LIMIT 1]){
            strFieldActionNumber = objTicketSearchResult.Ticket_Review__r.Field_Action_Number__c;
            strSearchFrequency = objTicketSearchResult.Ticket_Review__r.Search_Frequency__c;
            recordTypeName =  objTicketSearchResult.Ticket_Review__r.RecordType.Name;
        }

        isError = false;
        Map<Id, String> ticketFANMap = new Map<Id, String>();

        for(Ticket_Search_Result__c objTicketSearchResult : lstTicketSearchResults){
            //Defect #40 fix BEGIN
            if (objTicketSearchResult.Ticket_Review_Status__c == 'Related with Malfunction' 
                && String.isNotBlank(strSearchFrequency)  
                && strSearchFrequency.contains('14 days')  //Commented - 03MAY2019 - #870, #871 #909--  && String.isNotBlank(strSearchFrequency)  && strSearchFrequency.contains('14 days')
                && String.isNotBlank(recordTypeName)
                && recordTypeName.equals('Recurrence Search')) {  // Def HC #40/CHARM-3336: added condition to check record type
                ticketFANMap.put(objTicketSearchResult.Ticket__c, strFieldActionNumber);
                isRelatedwithMalfunction =  true;
            }
            //Defect #40 fix END
        }
        try{
            update lstTicketSearchResults;
            //Added W-000097
            if(!ticketFANMap.isEmpty()){
                updateRelatedMedEval(ticketFANMap);
            }
        }catch(Exception ex){
            isError = true;
            System.debug('======isError====='+isError + ex.getMessage());
        }
        return null;
    }

    /*
    * @Method       : getticketReviewStatusPicklists.
    * @Description  : This method is used to get Ticket_Search_Result__c object Ticket_Review_Status__c Field Picklist Values.
    * @Invoke       : From TicketSearchResultsReview page, onload.
    * @Return       : List<SelectOption>.
    * @Params       : N/A.
    */
    public List<SelectOption> getticketReviewStatusPicklists(){
        List<SelectOption> lstSelectOptions = new List<SelectOption>();
        lstSelectOptions.add(new SelectOption('', '--None--'));
        for(Schema.PicklistEntry objPicklistEntry : Ticket_Search_Result__c.Ticket_Review_Status__c.getDescribe().getPicklistValues()){
            lstSelectOptions.add(new SelectOption(objPicklistEntry.getLabel(), objPicklistEntry.getValue()));
        }
        return lstSelectOptions;
    }

    /*
    * @Method       : updateRelatedMedEval.
    * @Description  : Added W-000097 - method - To update related Med Evals.
    * @Invoke       : From TicketSearchResultsReview page, onload.
    * @Return       : N/A.
    * @Params       : Map<Id, String> relatedTicketsWithFAN.
    */
    public void updateRelatedMedEval(Map<Id, String> relatedTicketsWithFAN){
        //Updated - 26APR19 - Code was not correctly written

        Map<Id, CMPL123CME__Complaint__c> tickettoReopenMap = new Map<Id, CMPL123CME__Complaint__c>();
        List<CMPL123CME__Questionnaire__c> assessmentToInsert = new List<CMPL123CME__Questionnaire__c>();
        List<CMPL123CME__Questionnaire__c> assessmentToUpdate = new List<CMPL123CME__Questionnaire__c>();

        // Get the Workflow Steps
        Map<String, CMPL123__WF_Step__c> wfStepMap = new Map<String, CMPL123__WF_Step__c>();
        for(CMPL123__WF_Step__c wfStep : [SELECT Id, CMPL123__WF_Rule__r.CMPL123__Record_Type__c,
                                          CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
                                          FROM CMPL123__WF_Step__c
                                          WHERE (CMPL123__WF_Rule__r.CMPL123__Record_Type__c =: AspenConstants.STR_MEDICAL_EVALUATION_WORKFLOW
                                                 AND (CMPL123__Start_Status__r.Name =: AspenConstants.STR_Regulatory OR CMPL123__Start_Status__r.Name =: AspenConstants.STR_Closed_Done)
                                                 AND CMPL123__End_Status__r.Name =: AspenConstants.STR_In_Process_Evaluation
                                                 AND (CMPL123__Action__r.Name = 'Go to In Process-Evaluation' OR CMPL123__Action__r.Name = 'Reopen'))
                                          OR (CMPL123__Action__r.Name = 'Reopen' AND
                                              (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'COMPLAINT_WORKFLOW' OR CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'INQUIRY_WORKFLOW' OR CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'SERVICE_WORKFLOW'))]) {
                                                  wfStepMap.put(wfStep.CMPL123__WF_Rule__r.CMPL123__Record_Type__c+wfStep.CMPL123__Start_Status__r.Name, wfStep);
                                              }

        List<CMPL123__WF_History__c> wfHistoryRecords = new List<CMPL123__WF_History__c>();

        for(CMPL123CME__Complaint__c ticket
            : [SELECT Id,CMPL123Rule_Key_Value__c, CMPL123CME__CMPL123_WF_Status__c,
               (SELECT Id, CMPL123CME__Complaint__c,CMPL123Rule_Key_Value__c, CMPL123Task_Key_Value__c, CMPL123_WF_Status__c FROM CMPL123CME__Questionnaires__r WHERE CMPL123_WF_Status__c != 'Closed-Voided')
               FROM CMPL123CME__Complaint__c WHERE Id IN : relatedTicketsWithFAN.keySet()]){
                   if(ticket.CMPL123CME__Questionnaires__r.size() > 0 ){
                       for(CMPL123CME__Questionnaire__c quest : ticket.CMPL123CME__Questionnaires__r){
                           if(quest.CMPL123_WF_Status__c == 'Regulatory'){
                               CMPL123__WF_Step__c wfStep = wfStepMap.get(quest.CMPL123Rule_Key_Value__c+quest.CMPL123_WF_Status__c);
                               wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(quest.id, wfStep));

                               quest.CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name;
                               quest.CMPL123_WF_Action_Performed_On__c = DateTime.now();
                               quest.CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                               quest.CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name;
                               quest.Field_Action_Flag__c = true;
                               quest.Field_Action_Number__c = relatedTicketsWithFAN.get(quest.CMPL123CME__Complaint__c);
                               assessmentToUpdate.add(quest);
                           }else if(quest.CMPL123_WF_Status__c == 'In Process-Evaluation' || quest.CMPL123_WF_Status__c == 'Opened'){
                               quest.Field_Action_Flag__c = true;
                               quest.Field_Action_Number__c = relatedTicketsWithFAN.get(quest.CMPL123CME__Complaint__c);
                               assessmentToUpdate.add(quest);
                           }else if(quest.CMPL123_WF_Status__c == 'Closed-Done'){
                               CMPL123__WF_Step__c wfStep = wfStepMap.get(quest.CMPL123Rule_Key_Value__c+quest.CMPL123_WF_Status__c);
                               wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(quest.id, wfStep));
                               quest.CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name;
                               quest.CMPL123_WF_Action_Performed_On__c = DateTime.now();
                               quest.CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                               quest.CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name;
                               quest.Field_Action_Flag__c = true;
                               quest.Field_Action_Number__c = relatedTicketsWithFAN.get(quest.CMPL123CME__Complaint__c);
                               assessmentToUpdate.add(quest);
                           }
                       }
                   } else {
                       CMPL123CME__Questionnaire__c assess = new CMPL123CME__Questionnaire__c();
                       assess.CMPL123CME__Complaint__c = ticket.Id;
                       assess.Field_Action_Flag__c = true;
                       assess.Field_Action_Number__c = relatedTicketsWithFAN.get(ticket.Id);
                       assessmentToInsert.add(assess);
                   }

                   // Reopen Complaint
                   if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done') {
                       if(!tickettoReopenMap.containsKey(ticket.Id)){
                           CMPL123__WF_Step__c wfStep1 = wfStepMap.get(ticket.CMPL123Rule_Key_Value__c+ticket.CMPL123CME__CMPL123_WF_Status__c);
                           wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(ticket.id, wfStep1));
                           CMPL123CME__Complaint__c compl = new CMPL123CME__Complaint__c();
                           compl.CMPL123CME__CMPL123_WF_Status__c = wfStep1.CMPL123__End_Status__r.Name;
                           compl.CMPL123CME__CMPL123_WF_Action_Performed_On__c = DateTime.now();
                           compl.CMPL123CME__CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                           compl.CMPL123CME__CMPL123_WF_Action__c = wfStep1.CMPL123__Action__r.Name;
                           compl.Id = ticket.Id;
                           compl.Reopen_Rationale__c = 'Related to field action ' + relatedTicketsWithFAN.get(ticket.Id);
                           tickettoReopenMap.put(ticket.Id,compl);
                       }
                   }
               }

        try{
            if(tickettoReopenMap.size() > 0) {
                update tickettoReopenMap.values();
            }
            if(assessmentToInsert.size() > 0) {
                insert assessmentToInsert;
            }
            if(assessmentToUpdate.size() > 0) {
                Database.executeBatch(New UpdateMedEvalDecisionTreeBatch(assessmentToUpdate),1);
            }
            insert wfHistoryRecords;

        } catch(Exception de) {
            system.debug('Error' + de);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, de.getMessage()));
        }
    }
}