/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDDemoteToServiceHandler
* @Why   : Global class to demote a complaint ticket to service, Class to fetch the complaint ticket child and void them when the ticket is demoted to service.
* @When  : 23-MAR-2017
* @Where : From DemoteToService Page
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID        Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    23-MAR-2017            Work ID / Case ID      Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    18-DEC-2019            Defects #1606, #1655   Modified.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    23-DEC-2019            Defect #1658           Modified.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit             Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit             Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    22-DEC-2020            Upgrade issue #41      Added isDemotedOrPromoted flag.
* --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman                 1-JUL-2021             MIR Project            The system shall not allow a user to demote a complaint to service.
* --------------------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class ADDDemoteToServiceHandler {
    public String demotionValue { get; set; }
    // Method to fetch all the related open child records.
    public List<CMPL123CME__Complaint__c> complaintsWithchildsList { get; set; }

    //Defect #1658 fix BEGIN
    private static final Id serviceRecordTypeID = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
    //Defect #1658 fix END
    public static Boolean isDemotedOrPromoted = false;

    String ticketId = ApexPages.CurrentPage().getparameters().get('id');
    public String returnMessage { get; set; }

    /**
    * @Method       : Constructor
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To initialize the members of current class
    * @Return       : N/A
    * @Params       : N/A
    **/
    public ADDDemoteToServiceHandler() {
        returnMessage = 'Valid';

        if ([SELECT COUNT() FROM GroupMember WHERE Group.Name = 'Business Admin' AND UserOrGroupId = :Userinfo.getUserId()] > 0) {
            //Updated - W-000094
            //NOTE : Voiding Prod eval and customer response done on ComplaintTriggerHandler moveChildrenOpenToClose method
            complaintsWithchildsList = [
                    SELECT Id, Name, RecordType.Name, (
                            SELECT Id, Name,CMPL123_WF_Status__c
                            FROM Customer_Responses__r
                            WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                    ), (
                            SELECT Id, Name, CMPL123_WF_Status__c
                            FROM Returns__r
                            WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                    ), (
                            SELECT Id, Investigation_Evaluation__r.Name, Ticket__c, Type__c, Investigation_Evaluation__r.CMPL123_WF_Status__c
                            FROM Ticket_Product_Evaluation_Investigation__r
                            WHERE (NOT Investigation_Evaluation__r.CMPL123_WF_Status__c LIKE 'Closed%') AND Type__c = 'Source'
                    ), (
                            SELECT Id, Name, CMPL123_WF_Status__c
                            FROM Translation_Tasks__r
                            WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                    ), (
                            SELECT Id, Name, Registration_Ticket_Number__c, Ticket__c, Ticket__r.Registration_Ticket__c,
                                    Request_Status__c
                            FROM Meaningful_Data_Requests__r
                            WHERE Request_Status__c = 'Opened'
                    ), (
                            SELECT Id,Name,CMPL123_WF_Status__c,CMPL123Rule_Key_Value__c,CMPL123_WF_Action_Performed_By__c,CMPL123_WF_Action_Performed_On__c,
                                    CMPL123_WF_Action__c
                            FROM CMPL123CME__Questionnaires__r
                            WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                    )
                    FROM CMPL123CME__Complaint__c
                    Where Id = :ticketId
            ];

            CMPL123CME__Complaint__c complaintsWithEMDRchilds = [
                    SELECT Id, Name, RecordType.Name,MDC_All_ACKs_Received__c,
                            Overall_Reportable_Status__c, CMPL123CME__CMPL123_WF_Status__c, (
                            SELECT Id, Name, CMPL123CME__Complaint__c, CMPL123_WF_Status__c
                            FROM CMPL123CME__Questionnaires__r
                            WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                            LIMIT 1
                    ),
			(SELECT Id FROM CMPL123CME__MEDDEV__r WHERE CMPL123_WF_Status__c != 'Closed-Voided' LIMIT 1), 
                        // Added by Lakshman for FRS-1130-05
                	(SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__EU_MIR__r WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') LIMIT 1),
                        (SELECT Id, Name, CMPL123CME__Complaint__c, CMPL123CME__CMPL123_WF_Status__c
                            FROM CMPL123CME__EMDR__r
                            WHERE CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided'
                            LIMIT 1
                    ), //Added for defect 407
                    (SELECT Id FROM CMPL123CME__Investigations__r)
                    FROM CMPL123CME__Complaint__c
                    Where Id = :ticketId
                    LIMIT 1
            ];

            if (complaintsWithEMDRchilds.Overall_Reportable_Status__c == 'Reportable;Reported' ||
                    complaintsWithEMDRchilds.Overall_Reportable_Status__c == 'Reportable' ||
                    complaintsWithEMDRchilds.Overall_Reportable_Status__c == 'Reported'
                    //complaintsWithEMDRchilds.CMPL123CME__Questionnaires__r.size() > 0 ||
                    ) {
                returnMessage = 'NotReportable';
            } else if (complaintsWithEMDRchilds.CMPL123CME__Questionnaires__r.size() > 0) {
                returnMessage = 'OpenedMedeval';
            } else if (complaintsWithEMDRchilds.CMPL123CME__EMDR__r.size() > 0) {
                returnMessage = 'openedEmdr';
            } else if (complaintsWithEMDRchilds.CMPL123CME__MEDDEV__r.size() > 0) {
                returnMessage = 'openedMdi';
            } else if (complaintsWithEMDRchilds.CMPL123CME__EU_MIR__r.size() > 0) { // Added by Lakshman for FRS-1130-05
                returnMessage = 'openedMir';
            } else if (complaintsWithEMDRchilds.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' ||
                    complaintsWithEMDRchilds.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Voided') {
                returnMessage = 'Closed';
            } else if (!complaintsWithEMDRchilds.MDC_All_ACKs_Received__c) {
                returnMessage = 'PendingMDC';
            } else {
                Set<String> investigationIds = new Set<String>();
                for (CMPL123CME__Investigation__c inv : complaintsWithEMDRchilds.CMPL123CME__Investigations__r) {
                    investigationIds.add(inv.Id);
                }

                returnMessage = [
                        SELECT COUNT()
                        FROM Ticket_Product_Evaluation_Investigation__c
                        WHERE
                        Investigation_Evaluation__c IN :investigationIds
                        AND Type__c = 'Leveraged' AND Ticket__c != :ticketId
                ] > 0 ? 'Leverage' : 'Valid';

            }
        } else {
            returnMessage = 'NoAccess';
        }
    }

    /**
    * @Method       : updateDemotionValue
    * @Invoke       : From DemoteToService page
    * @Description  : Method to update workflow in child and ticket field updates after the demotion
    * @Return       : PageReference
    * @Params       : N/A
    **/
    //Method to update workflow in child and ticket field updates after the demotion
    // Updated - W-000094
    public PageReference updateDemotionValue() {
        isDemotedOrPromoted = true;
        //NOTE : Voiding Prod eval and customer response done on ComplaintTriggerHandler moveChildrenOpenToClose method
        String ticketId = ApexPages.CurrentPage().getparameters().get('id');
        Map<String, CMPL123__WF_Step__c> wfStepMap = new Map<String, CMPL123__WF_Step__c>();
        List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
        List<Return__c> updatedReturnsList = new List<Return__c>();
        List<CMPL123CME__Complaint__c> updatedTicketList = new List<CMPL123CME__Complaint__c>();
        List<Translation_Task__c> updatedTranslationTaskList = new List<Translation_Task__c>();
        List<Meaningful_Data_Request__c> updatedMeaningfulDataReqList = new List<Meaningful_Data_Request__c>();
        List<CMPL123CME__Questionnaire__c> updatedQuestionnaireList = new List<CMPL123CME__Questionnaire__c>();
        //UPDATED W-000094
        Set<Id> setProdEvalIds = new Set<Id>();
        Set<Id> setMedicalEvaluation = new Set<Id>();
        List<Task__c> updatedTaskList = new List<Task__c>();
        List<Medical_Evaluation_Task__c> updatedMedicalEvaluationTask = new List<Medical_Evaluation_Task__c>();
        //UPDATED W-000094

        //Get workflow steps = //UPDATED W-000094 (updated for Prod_Eval_Task)
        Map<String, CMPL123__WF_Step__c> mapWFStepWithRuleKey = New Map<String, CMPL123__WF_Step__c>();
        for (CMPL123__WF_Step__c wfStep : [
                SELECT Id, CMPL123__WF_Rule__r.CMPL123__Record_Type__c,
                        CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
                FROM CMPL123__WF_Step__c
                WHERE
                ((CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'PRODEVAL_WORKFLOW'
                OR CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'PRODEVAL_WORKFLOW_AMD')
                AND
                (CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided' AND
                CMPL123__Start_Status__r.Name = 'Assess'))
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'RETURN_WORKFLOW' AND
                CMPL123__Start_Status__r.Name = 'Opened' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Prod_Eval_Task' AND
                CMPL123__Start_Status__r.Name = 'Opened' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Complaint_Customer_Response' AND
                CMPL123__Start_Status__r.Name = 'Opened' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task' AND
                CMPL123__Start_Status__r.Name = 'In Process' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_WORKFLOW' AND
                CMPL123__Start_Status__r.Name = 'In Process-Evaluation' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'MEDICAL_EVALUATION_TASK_WORKFLOW' AND
                CMPL123__Start_Status__r.Name = 'In Process' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                //Defects #1606 and 1655 fix:
                // added query to read configuration records for analysis tasks (Task_Analysis);
                // adjusted Tickets_Task query according to WF configuration;
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Tickets_Task' AND
                CMPL123__Start_Status__r.Name = 'Opened' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
                OR
                (CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Task_Analysis' AND
                CMPL123__Start_Status__r.Name = 'Opened' AND
                CMPL123__Action__r.Name = 'Void' AND CMPL123__End_Status__r.Name = 'Closed-Voided')
        ]) {
            wfStepMap.put(wfStep.CMPL123__WF_Rule__r.CMPL123__Record_Type__c, wfStep);
        }
        //Udated - W-000094
        for (CMPL123CME__Complaint__c ticket : [
                SELECT Id, Name, RecordType.Name,
                        Complaint_Demotion_rationale__c,Ticket_Type__c,Issue_code__c,
                        Is_Product_Evaluation_Investigation_chil__c,CMPL123Rule_Key_Value__c,
                        Customer_Reply_Required__c,Is_Custom_response_child_created__c, (
                        SELECT Id, Name, CMPL123Rule_Key_Value__c,
                                CMPL123_WF_Status__c,CMPL123_WF_Action_Performed_On__c,
                                CMPL123_WF_Action_Performed_By__c, CMPL123_WF_Action__c
                        FROM CMPL123CME__Investigations__r
                        WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                ), (
                        SELECT Id, Name,CMPL123_WF_Status__c,CMPL123Rule_Key_Value__c,
                                CMPL123_WF_Action_Performed_On__c,
                                CMPL123_WF_Action_Performed_By__c, CMPL123_WF_Action__c
                        FROM Customer_Responses__r
                        WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                ), (
                        SELECT Id, Name, CMPL123_WF_Status__c, CMPL123Rule_Key_Value__c,
                                CMPL123_WF_Action_Performed_On__c,
                                CMPL123_WF_Action_Performed_By__c, CMPL123_WF_Action__c
                        FROM Returns__r
                        WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                ), (
                        SELECT Id, Name, CMPL123_WF_Status__c, CMPL123_WF_Action_Performed_On__c, CMPL123_WF_Action_Performed_By__c,
                                CMPL123_WF_Action__c,CMPL123Rule_Key_Value__c
                        FROM Translation_Tasks__r
                        WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                ), (
                        SELECT Id, Name, Registration_Ticket_Number__c, Ticket__c, Ticket__r.Registration_Ticket__c,
                                Request_Status__c
                        FROM Meaningful_Data_Requests__r
                        WHERE Request_Status__c = 'Opened'
                ), (
                        SELECT Id,Name,CMPL123_WF_Status__c,CMPL123Rule_Key_Value__c,CMPL123_WF_Action_Performed_By__c,CMPL123_WF_Action_Performed_On__c,
                                CMPL123_WF_Action__c
                        FROM CMPL123CME__Questionnaires__r
                        WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%')
                )
                FROM CMPL123CME__Complaint__c
                Where Id = :ticketId
        ]) {

            for (CMPL123CME__Investigation__c objInvestigation : ticket.CMPL123CME__Investigations__r) {
                setProdEvalIds.add(objInvestigation.Id);
            }

            // Workflow insert for return
            for (Return__c returnChild : ticket.Returns__r) {
                if (returnChild.CMPL123_WF_Status__c != 'Closed-Voided' && returnChild.CMPL123_WF_Status__c != 'Closed-Done') {
                    CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(returnChild.Id, wfStepMap.get(returnChild.CMPL123Rule_Key_Value__c));
                    wfHistory.CMPL123__Comment__c = demotionValue;
                    WFHistories.add(wfHistory);

                    updatedReturnsList.add(new Return__c(Id = returnChild.Id,
                            CMPL123_WF_Status__c =
                                    wfStepMap.get(returnChild.CMPL123Rule_Key_Value__c).CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action_Performed_On__c = System.now(),
                            CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                            CMPL123_WF_Action__c =
                                    wfStepMap.get(returnChild.CMPL123Rule_Key_Value__c).CMPL123__Action__r.Name
                    ));
                }
            }

            //Workflow inser for Translation Task
            for (Translation_Task__c translationTaskChild : ticket.Translation_Tasks__r) {
                if (translationTaskChild.CMPL123_WF_Status__c != 'Closed-Voided' && translationTaskChild.CMPL123_WF_Status__c != 'Closed-Done') {
                    CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(translationTaskChild.Id, wfStepMap.get(translationTaskChild.CMPL123Rule_Key_Value__c));
                    wfHistory.CMPL123__Comment__c = demotionValue;
                    WFHistories.add(wfHistory);
                    updatedTranslationTaskList.add(new Translation_Task__c(Id = translationTaskChild.Id,
                            CMPL123_WF_Status__c =
                                    wfStepMap.get(translationTaskChild.CMPL123Rule_Key_Value__c).CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action_Performed_On__c = System.now(),
                            CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                            CMPL123_WF_Action__c =
                                    wfStepMap.get(translationTaskChild.CMPL123Rule_Key_Value__c).CMPL123__Action__r.Name,
                            Void_Rationale__c = demotionValue
                    ));
                }
            }

            //Change status of meaningful Data Request
            for (Meaningful_Data_Request__c mdr : ticket.Meaningful_Data_Requests__r) {
                if (mdr.Request_Status__c == 'Opened') {
                    updatedMeaningfulDataReqList.add(new Meaningful_Data_Request__c(Id = mdr.Id, Request_Status__c = 'Voided',
                            Answer_No_Answer_Rationale__c = 'Provided during demoting a ticket to service'));
                }
            }

            //Update ticket
            updatedTicketList.add(new CMPL123CME__Complaint__c(Id = ticket.Id,
                    Complaint_Demotion_rationale__c = demotionValue,
                    Demotion_rationale__c = demotionValue,
                    Complaint_Demoted_By__c = UserInfo.getName(),
                    Complaint_Demotion_Date__c = System.Now(),
                    Ticket_Type__c = 'Service',
                    Is_Product_Evaluation_Investigation_chil__c = false,
                    CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
                    Issue_code__c = '',
                    //Defect #1658 fix BEGIN
                    Issue_code_Description__c = '',
                    //RecordTypeId = serviceRecordTypeID, - Please don't
                    //Defect #1658 fix END
                    Customer_Reply_Required__c = false/*,
                    Is_Custom_response_child_created__c = false*/));

            //update Medical Evaluation
            for (CMPL123CME__Questionnaire__c objQuestionnaire : ticket.CMPL123CME__Questionnaires__r) {

                if (objQuestionnaire.CMPL123_WF_Status__c != 'Closed-Voided' && objQuestionnaire.CMPL123_WF_Status__c != 'Closed-Done') {
                    setMedicalEvaluation.add(objQuestionnaire.Id);
                    CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(objQuestionnaire.Id, wfStepMap.get(objQuestionnaire.CMPL123Rule_Key_Value__c));
                    wfHistory.CMPL123__Comment__c = demotionValue;
                    WFHistories.add(wfHistory);

                    updatedQuestionnaireList.add(new CMPL123CME__Questionnaire__c(Id = objQuestionnaire.Id,
                            Voided_Rationale__c = demotionValue,
                            CMPL123_WF_Status__c =
                                    wfStepMap.get(objQuestionnaire.CMPL123Rule_Key_Value__c).CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action_Performed_On__c = System.now(),
                            CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                            CMPL123_WF_Action__c =
                                    wfStepMap.get(objQuestionnaire.CMPL123Rule_Key_Value__c).CMPL123__Action__r.Name
                    ));
                }
            }
        }

        //UPDATED W-000094
        //Workflow inser for Prod Eval Task - grandchild record
        if (setProdEvalIds.size() > 0) {

            for (Task__c objTask : [
                    SELECT Id, Name, CMPL123Rule_Key_Value__c, CMPL123_WF_Status__c,
                            CMPL123_WF_Action_Performed_On__c, CMPL123_WF_Action_Performed_By__c,
                            CMPL123_WF_Action__c
                    FROM Task__c
                    WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') AND Related_Investigation_Evaluation__c IN:setProdEvalIds
            ]) {
                if (!objTask.CMPL123_WF_Status__c.contains('Closed')) {
                    CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(objTask.Id, wfStepMap.get(objTask.CMPL123Rule_Key_Value__c));
                    wfHistory.CMPL123__Comment__c = demotionValue;
                    WFHistories.add(wfHistory);
                    updatedTaskList.add(new Task__c(Id = objTask.Id,
                            CMPL123_WF_Status__c =
                                    wfStepMap.get(objTask.CMPL123Rule_Key_Value__c).CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action_Performed_On__c = System.now(),
                            CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                            CMPL123_WF_Action__c =
                                    wfStepMap.get(objTask.CMPL123Rule_Key_Value__c).CMPL123__Action__r.Name
                    ));
                }
            }
        }

        //Medeval child records(Medical Evaluation Task)
        if (setMedicalEvaluation.size() > 0) {
            // Get all child records related to parent Medeval
            for (Medical_Evaluation_Task__c objMedicalEvaluationTask : [
                    SELECT Id, Name, CMPL123Rule_Key_Value__c, CMPL123_WF_Status__c,
                            CMPL123_WF_Action_Performed_On__c, CMPL123_WF_Action_Performed_By__c,
                            CMPL123_WF_Action__c
                    FROM Medical_Evaluation_Task__c
                    WHERE (NOT CMPL123_WF_Status__c LIKE 'Closed%') AND Medical_Evaluation__c IN:setMedicalEvaluation
            ]) {
                if (objMedicalEvaluationTask.CMPL123_WF_Status__c != 'Closed-Voided' && objMedicalEvaluationTask.CMPL123_WF_Status__c != 'Closed-Done') {
                    CMPL123__WF_History__c wfHistory = ComplaintTriggerHandler.processAutomatedHistoryRecord(objMedicalEvaluationTask.Id, wfStepMap.get(objMedicalEvaluationTask.CMPL123Rule_Key_Value__c));
                    wfHistory.CMPL123__Comment__c = demotionValue;
                    WFHistories.add(wfHistory);
                    updatedMedicalEvaluationTask.add(new Medical_Evaluation_Task__c(Id = objMedicalEvaluationTask.Id,
                            CMPL123_WF_Status__c =
                                    wfStepMap.get(objMedicalEvaluationTask.CMPL123Rule_Key_Value__c).CMPL123__End_Status__r.Name,
                            CMPL123_WF_Action_Performed_On__c = System.now(),
                            CMPL123_WF_Action_Performed_By__c = userinfo.getuserid(),
                            CMPL123_WF_Action__c =
                                    wfStepMap.get(objMedicalEvaluationTask.CMPL123Rule_Key_Value__c).CMPL123__Action__r.Name
                    ));
                }
            }
        }

        if (updatedReturnsList.size() > 0) {
            update updatedReturnsList;
        }
        if (updatedTranslationTaskList.size() > 0) {
            update updatedTranslationTaskList;
        }
        if (updatedMeaningfulDataReqList.size() > 0) {
            update updatedMeaningfulDataReqList;
        }


        //UPDATED W-000094
        if (updatedTaskList.size() > 0) {
            update updatedTaskList;
        }
        if (updatedTicketList.size() > 0) {
            update updatedTicketList;
        }
        if (updatedMedicalEvaluationTask.size() > 0) {
            update updatedMedicalEvaluationTask;
        }
        if (updatedQuestionnaireList.size() > 0) {
            update updatedQuestionnaireList;
        }
        if (WFHistories.size() > 0) {
            insert WFHistories;
        }

        PageReference pageRef = new PageReference('/' + ticketId);

        return pageRef;
    }
    
    /**
    * @Method       : cancelDemotion
    * @Invoke       : DemoteToService page
    * @Description  : This method returns an empty pagereference
    * @Return       : PageReference
    * @Params       : N/A
    **/
    public PageReference cancelDemotion() {
        PageReference pageRef = new PageReference('/' + ticketId);
        return pageRef;
    }
}