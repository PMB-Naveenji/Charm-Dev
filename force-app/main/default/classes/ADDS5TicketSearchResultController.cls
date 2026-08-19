/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS5TicketSearchResultController.
* @Why   : Handles all the customization involved on Ticket Search Result object.
* @When  : 06-APR-2017.
* @Where : From TicketResultSearchVFPage page, ADDS5DisplayTicketSearchResults page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  06-APR-2017			 Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   01-APR-2020            N/A                       Added formatting to the class and also added
*                                                                          populating for 'Initial Awarness Date' to be covered by unit test.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020            Code Audit                Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   13-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS5TicketSearchResultController {

    public Integer size {get; set;}
    public Integer noOfRecords {get; set;}
    public List<Integer> pageNumberList;
    public Integer toPageNumber {get; set;}
    public List<SelectOption> pageSizeOptions {get; set;}
    public string ticketReviewId;
    public Boolean isError{get; private set;}

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From TicketResultSearchVFPage page, ADDS5DisplayTicketSearchResults page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public ADDS5TicketSearchResultController(ApexPages.StandardController controller){
        ticketReviewId = ApexPages.currentPage().getParameters().get('TRID');

        size = 10;
        pageSizeOptions = new List<SelectOption>();
        pageSizeOptions.add(new SelectOption('5','5'));
        pageSizeOptions.add(new SelectOption('10','10'));
        pageSizeOptions.add(new SelectOption('20','20'));
        pageSizeOptions.add(new SelectOption('50','50'));
        pageSizeOptions.add(new SelectOption('100','100'));
        //getTicketSearchResultsList();
        isError = false;
    }

    public PageReference setPgNumber() {
        setCon.setPageNumber(toPageNumber);
        return null;
    }

    //Changes the size of pagination
    public PageReference changePageSize() {
         setCon.setPageSize(size);
         return null;
    }

    public List<Integer> getPageNumberList() {
        Integer startIndex = 0;
        Integer endIndex = 0;
        Integer totalNumberofPages = 0;
        Integer currentPageNumber = setCon.getPageNumber();
        List<Integer> tempPageNumberList = new List<Integer>();

        if(math.mod(setCon.getResultSize(), size) == 0) {
            totalNumberofPages = setCon.getResultSize() / size;
        } else {
            totalNumberofPages = (setCon.getResultSize() / size) + 1;
        }

        if(totalNumberofPages > 0) {

            startIndex = currentPageNumber - 10;
            endIndex = currentPageNumber + 10;

            if(startIndex < 1) {
                startIndex = 1;
            }
            if(endIndex > totalNumberofPages) {
                endIndex = totalNumberofPages;
            }

            for(Integer i=startIndex; i<=endIndex; i++) {
                tempPageNumberList.add(i);
            }
            return tempPageNumberList;

        } else {
            return null;
        }
    }

    public ApexPages.StandardSetController setCon {
        get {
            //W-000321 - Added Product Name and Experience Code in the query string
            if(setCon == null) {
                String queryString = 'SELECT Id, Ticket__c, Name, Ticket_Registration_Number__c, Association_Date__c, FA_Quality_Assignee_Pending_MDCs__c, ' +
                    'Ticket_Overall_Reportablity__c, Ticket_Quality_Directive_Num_Modify_Date__c, Ticket_Quality_Directive_Number__c, Med_Evaluator_Pending_MDCs__c,' +
                    'FA_Mandatory_TSB_number__c, MDC_Last_Updated_Date__c, Ticket_Review_Status__c, Not_Related_Rationale__c, ' +
                    'Ticket_Review_Status_Date__c, Awareness_Date__c, Medical_Comments__c, Submission_Information__c, Medical_Evaluator__c, ' +
                    'Ticket_Review_Status_Hidden__c, Ticket_Review__c, Ticket_Review__r.Number_of_tickets__c, Ticket_Review__r.Search_Frequency__c, Ticket_Review__r.Field_Action_Number__c, ' +
                    'Ticket__r.Product_Name__c, Ticket__r.Experience_code__c,Ticket_Review__r.Status__c FROM Ticket_Search_Result__c WHERE Ticket_Review__c =: ticketReviewId ORDER BY CreatedDate LIMIT 1001';
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
            }
            setCon.setPageSize(size);
            noOfRecords = setCon.getResultSize();
            return setCon;
        }
        set;
    }

    public List<Ticket_Search_Result__c> ticketSearchResultsList {

        get {
            List<Ticket_Search_Result__c> ticketTempList = new List<Ticket_Search_Result__c>();
            //ticketTempList = setCon.getRecords().deepClone(true, true, true);
            ticketTempList = (List<Ticket_Search_Result__c>) setCon.getRecords();
            if(ticketTempList.size() > 0 && ticketTempList[0].Ticket_Review__r.Status__c == 'Active') {
                return ticketTempList;
            } else if(ticketTempList.size() == 0) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.Ticket_Review_No_Search_Results));
                return null;
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.Ticket_Review_Cannot_Display_Search_Results));
                return null;
            }
        }
        set;

    }

    /*
    * @Method       : processTicketSearchResults.
    * @Description  : To handle events on Ticket search result.
    * @Invoke       : From TicketResultSearchVFPage page, ADDS5DisplayTicketSearchResults page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void processTicketSearchResults(){
        isError = false;
        List<Ticket_Search_Result__c> tickSearchUpdList = new List<Ticket_Search_Result__c>();
        tickSearchUpdList = (List<Ticket_Search_Result__c>) setCon.getRecords();
        update ticketSearchResultsList;


        Map<Id, String> ticketFANMap = new Map<Id, String>();

        for(Ticket_Search_Result__c ts : ticketSearchResultsList){
            if(ts.Ticket_Review_Status__c == 'Related with Malfunction' && String.isNotBlank(ts.Ticket_Review__r.Search_Frequency__c) && ts.Ticket_Review__r.Search_Frequency__c.contains('14 days')){
                ticketFANMap.put(ts.Ticket__c, ts.Ticket_Review__r.Field_Action_Number__c);
            }
        }
        try{
            //Added W-000097
            updateRelatedMedEval(ticketFANMap);
            update ticketSearchResultsList;
        }catch(Exception ex){
            isError = true;
            System.debug('======isError====='+isError);
        }
    }

    /*
    * @Method       : updateRelatedMedEval.
    * @Description  : To handle events on CMPL complaints and Questionnaire.
    * @Invoke       : From ADDS5TicketSearchResultController class.
    * @Return       : N/A.
    * @Params       : Map<Id, String> relatedTicketsWithFAN.
    */
    public void updateRelatedMedEval(Map<Id, String> relatedTicketsWithFAN){
        List<CMPL123CME__Complaint__c> tickettoReopenList = new List<CMPL123CME__Complaint__c>();
        List<CMPL123CME__Questionnaire__c> assessmentToInsert = new List<CMPL123CME__Questionnaire__c>();
        List<CMPL123CME__Questionnaire__c> assessmentToUpdate = new List<CMPL123CME__Questionnaire__c>();

        List<CMPL123CME__Complaint__c> objTicketList = [SELECT Id,CMPL123Rule_Key_Value__c, CMPL123CME__CMPL123_WF_Status__c,
                                                            (SELECT Id, CMPL123CME__Complaint__c,CMPL123Rule_Key_Value__c, CMPL123Task_Key_Value__c, CMPL123_WF_Status__c
                                                                FROM CMPL123CME__Questionnaires__r
                                                                WHERE CMPL123_WF_Status__c != 'In Process-Evaluation')
                                                        FROM CMPL123CME__Complaint__c WHERE Id IN : relatedTicketsWithFAN.keySet() ];

        // Get the Workflow Steps
        Map<String, CMPL123__WF_Step__c> wfStepMap = new Map<String, CMPL123__WF_Step__c>();
        for(CMPL123__WF_Step__c wfStep : [SELECT Id, CMPL123__WF_Rule__r.CMPL123__Record_Type__c,
                                          CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
                                          FROM CMPL123__WF_Step__c
                                          WHERE (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW' AND
                                          (CMPL123__Action__r.Name = 'Reopen-Go to Evaluation' OR CMPL123__Action__r.Name = 'Go to In Process-Evaluation')) OR (CMPL123__Action__r.Name = 'Reopen' AND CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'COMPLAINT_WORKFLOW')]) {
                                              wfStepMap.put(wfStep.CMPL123__WF_Rule__r.CMPL123__Record_Type__c+wfStep.CMPL123__Start_Status__r.Name, wfStep);
                                          }
        List<CMPL123__WF_History__c> wfHistoryRecords = new List<CMPL123__WF_History__c>();

        for (CMPL123CME__Complaint__c ticket :objTicketList) {
            if (ticket.CMPL123CME__Questionnaires__r.size() > 0 ) {
                for (CMPL123CME__Questionnaire__c quest :ticket.CMPL123CME__Questionnaires__r) {
                    if (quest.CMPL123_WF_Status__c == 'Regulatory') {
                        CMPL123__WF_Step__c wfStep = wfStepMap.get(quest.CMPL123Rule_Key_Value__c+quest.CMPL123_WF_Status__c);
                        wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(quest.id, wfStep));

                        quest.CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name;
                        quest.CMPL123_WF_Action_Performed_On__c = DateTime.now();
                        quest.CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                        quest.CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name;
                        quest.Field_Action_Flag__c = true;
                        quest.Field_Action_Number__c = relatedTicketsWithFAN.get(quest.CMPL123CME__Complaint__c);
                        quest.Initial_Awareness_Date__c = Date.today();

                        assessmentToUpdate.add(quest);
                    } else if (quest.CMPL123_WF_Status__c == 'Closed-Done') {
                        CMPL123__WF_Step__c wfStep = wfStepMap.get(quest.CMPL123Rule_Key_Value__c+quest.CMPL123_WF_Status__c);
                        wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(quest.id, wfStep));

                        quest.CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name;
                        quest.CMPL123_WF_Action_Performed_On__c = DateTime.now();
                        quest.CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                        quest.CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name;
                        quest.Field_Action_Flag__c = true;
                        quest.Field_Action_Number__c = relatedTicketsWithFAN.get(quest.CMPL123CME__Complaint__c);
                        quest.Initial_Awareness_Date__c = Date.today();

                        assessmentToUpdate.add(quest);

                        // Reopen MedEval
                        if (ticket.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done') {
                            CMPL123__WF_Step__c wfStep1 = wfStepMap.get(ticket.CMPL123Rule_Key_Value__c + ticket.CMPL123CME__CMPL123_WF_Status__c);
                            wfHistoryRecords.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(ticket.id, wfStep1));
                            CMPL123CME__Complaint__c compl = new CMPL123CME__Complaint__c();
                            compl.CMPL123CME__CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name;
                            compl.CMPL123CME__CMPL123_WF_Action_Performed_On__c = DateTime.now();
                            compl.CMPL123CME__CMPL123_WF_Action_Performed_By__c = userinfo.getuserid();
                            compl.CMPL123CME__CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name;
                            compl.Id = ticket.Id;
                            compl.Reopen_Rationale__c = 'Related to field action ' + relatedTicketsWithFAN.get(quest.CMPL123CME__Complaint__c);
                            tickettoReopenList.add(compl);
                        }
                    }
                }
            } else {
                CMPL123CME__Questionnaire__c assess = new CMPL123CME__Questionnaire__c();
                assess.CMPL123CME__Complaint__c = ticket.Id;
                assessmentToInsert.add(assess);
            }
        }
        try {
            if (tickettoReopenList.size() > 0) {
                update tickettoReopenList;
            }

            if (assessmentToInsert.size() > 0) {
                insert assessmentToInsert;
            }

            if (assessmentToUpdate.size() > 0) {
                Database.executeBatch(New UpdateMedEvalDecisionTreeBatch(assessmentToUpdate), 1);
                insert wfHistoryRecords;
            }
       } catch (Exception de) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, de.getMessage()));
       }
    }

}