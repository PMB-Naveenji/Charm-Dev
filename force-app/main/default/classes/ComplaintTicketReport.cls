/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ComplaintTicketReport
* @Why   : Queries Tickets and related records from database based on incoming Ticket Ids
* @When  : 16-MAY-2020
* @Where : From ADDComplaintReportController
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    16-MAY-2020            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    09-JUN-2020            Defect #106          Added fields "Ticket_Receipt_Date_GMT__c",
*                                                                      "Ticket_Close_Date_GMT__c" to query.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit           Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    02-JUL-2020            Code Audit           Added header class description and methods comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    20-AUG-2020            Code Audit           Updated class comments. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    07-SEP-2020            PMD report fixes     Removed SOQL's from loop.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    02-NOV-2020            HC Defect #44        Divided attachments query into multiple smaller queries to fix
*                                                                      query locator issue
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    23-NOV-2020            HC Defect #44        Divided tickets with child query into multiple smaller queries to
*                                                                      fix query locator issue
* --------------------------------------------------------------------------------------------------------------------------------------
 
*   Lakshman               03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G7_Type_of_Report_MultiSelect__c -> CMPL123CME__G6_Type_of_Report__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Sameer                 09-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G9_MFR_Report_Number__c -> CMPL123CME__G8_MFR_Report_Number__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Aslam,Larry            17-Sep-2021            Charm Release 2      Referenced wrong EU MIR fields
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Dinesh Kumar           16-JAN-2024            CHaRM-R4.0           EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" 
                                                                       discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c".
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ComplaintTicketReport {
    /**
    * @Method       : Generate
    * @Invoke       : From ADDComplaintReportController
    * @Description  : Queries Tickets and related records from database based on incoming Ticket Ids.
    * @Return       : List<ComplaintTicketReportResult>
    * @Params       : List<string> ids
    **/
    public static List<ComplaintTicketReportResult> Generate(List<string> ids) {
        Map <Id, ComplaintTicketReportResult> result = new Map <Id, ComplaintTicketReportResult> ();
        List <Id> ticketIds = new List <Id> ();
        //Changed in scope of a defect #106: Fields "Ticket_Receipt_Date_GMT__c", "Ticket_Close_Date_GMT__c" were added to query
        //HC Defect #44 BEGIN
        List <CMPL123CME__Complaint__c> ticketsList =
            [SELECT Id, CMPL123CME__Customer__r.Name, Customer_Name_Translated__c, Ticket_origination_Date__c,
                    Country_of_origin__c, Product_Evaluation_Start_Date__c, Investigation_Status__c,
                    Registration_Ticket_Owner__c, CMPL123CME__Customer__r.Contact_Address_Line_1__c,
                    CMPL123CME__Customer__r.Contact_Address_Line_2__c, Division__c, Receipt_Date__c,
                    Ticket_Receipt_Date__c, Ticket_Receipt_Date_GMT__c, Ticket_Close_Date_GMT__c,
                    Ticket_Close_Date__c, Ticket_CloseDate__c, Description_Translated__c,pRE_Status__c,
                    Investigation_Conclusion__c,Overall_Reportable_Status__c, Was_an_Adverse_Event_Identified__c,
                    Ticket_Description__c, Error_code__c, Issue_Code_Description_Concat__c, Experience_code__c,
                    Trending_Experience_Bucket__c, Quality_Directive_Number__c, Quality_Directive_Revision__c,
                    CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, Returns_Available__c,
                    Description_of_Available_Returns__c, Registration_Ticket_Number__c, CMPL123CME__Customer__r.City__c,
                    CMPL123CME__Customer__r.State__c, CMPL123CME__Customer__r.Zip_Postal_Code__c, CMPL123CME__Customer__r.Country__c,
                    Ticket_Type__c, Experience_Code_Description_Concat__c, Trending_Issue_Bucket_Description_Concat__c
             FROM CMPL123CME__Complaint__c
             WHERE CMSNext_Ticket_Number__c IN :ids
             LIMIT 50];
        Map <Id, List <Product_Ticket__c>> productTicketsByTicket = 
            GroupBy.id(
                'Event_Ticket__c', 
                [SELECT Id, Likely_Cause__c, Product_Name__c, Product_List_Number__c, Batch_Lot_Serial__c, Event_Ticket__c
                 FROM Product_Ticket__c
                 WHERE Event_Ticket__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <Contact__c>> contactsByTicket = 
            GroupBy.id(
                'Ticket__c',
                [SELECT Id, Name, Name__c, Contact_Name_Translated__c, Contact_Phone_Number__c, Occupation__c, Ticket__c,
                        Contact_Occupation_Translated__c 
                 FROM Contact__c 
                 WHERE Primary__c = true
                       AND Ticket__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <Ticket_Note__c>> ticketNotesByTicket = 
            GroupBy.id(
                'Ticket__c',
                [SELECT Id, Ticket_Notes_Created_By__c, Ticket_Notes_Created_Date__c, 
                        Ticket_Notes_Native__c, Ticket_Notes_Translated__c, Ticket__c
                 FROM Ticket_Note__c
                 WHERE Ticket__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <Activity__c>> activitiesByTicket = 
            GroupBy.id(
                'Complaint__c',
                [SELECT Id, Work_Done_Code__c, Work_Done_Description__c, Work_Done_Code_Description__c,
                        Work_Done_Likely_Cause__c, Performed_By__c, Complaint__c
                 FROM Activity__c
                 WHERE Complaint__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <Customer_Response__c>> customerResponsesByTicket = 
            GroupBy.id(
                'Event__c',
                [SELECT Id, Name, Customer_Expectation__c, Customer_Reply__c, Customer_Expectation_Translated__c,
                        Additional_Reply_Expectation_Translated__c, Additional_Reply_Expectation__c, Event__c
                 FROM Customer_Response__c
                 WHERE Event__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <Meaningful_Data__c>> meaningfulDatasByTicket = 
            GroupBy.id(
                'Compliant__c',
                [SELECT Id, Mean__c, Meaningful_Data_Answers__c, Meaningful_data_Answer_Translated__c, Compliant__c
                 FROM Meaningful_Data__c
                 WHERE Compliant__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <CMPL123CME__Questionnaire__c>> assessmentsByTicket = 
            GroupBy.id(
                'CMPL123CME__Complaint__c',
                [SELECT Id, Initial_Awareness_Date__c, Follow_Up_Awareness_Date__c, Agency__c, Submitted_Date__c, 
                        Reportability__c, Reportability_Date__c, Adverse_Event__c, Reportability_Category__c, 
                        Field_Action_Flag__c, pRE_Status__c, Field_Action_Number__c, CMPL123CME__Complaint__c
                 FROM CMPL123CME__Questionnaire__c
                 WHERE CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <CMPL123CME__EMDR__c>> emdrsByTicket = 
            GroupBy.id(
                'CMPL123CME__Complaint__c',
                [SELECT Id, CMPL123CME__Submitted_Date_Time__c, E1_Country1__c, CMPL123CME__E1_Country__c, Name, Void_Rational__c,
                        CMPL123CME__D1_Brand_Name__c,CMPL123CME__D4_Serial_No__c, CMPL123CME__EMDR_MFR__c, Submission_Type__c,
                        Classification__c, CMPL123CME__Submitted_By__c, CMPL123CME__D4_Catalog_No__c, CMPL123CME__CMPL123_WF_Status__c,
                        CMPL123CME__D4_Lot_No__c, CMPL123CME__G1_Mfg_Name__c, CMPL123CME__G8_MFR_Report_Number__c,
                 //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c" and also added "D4_Primary_UDI_Unique_Identifier__c".
                        //CMPL123CME__G6_Type_of_Report__c, CMPL123CME__Unique_Identifier_UDI__c, CMPL123CME__MFR_Report_Ref__c,
                        CMPL123CME__G6_Type_of_Report__c, CMPL123CME__D4_Primary_UDI_Number__c, D4_Primary_UDI_Unique_Identifier__c, CMPL123CME__MFR_Report_Ref__c,
                        CMPL123CME__Complaint__c
                 FROM CMPL123CME__EMDR__c
                 WHERE CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c IN :ids]
            );
        Map <Id, List <CMPL123CME__MEDDEV__c>> meddevsByTicket = 
            GroupBy.id(
                'CMPL123CME__Complaint__c',
                [SELECT Id, CMPL123CME__Manufacturer_Reference_Number__c, CMPL123CME__Submitter_Name__c, CMPL123CME__Commercial_Name__c,
                        CMPL123CME__HealthcareCountry__c, CMPL123CME__Serial_Numbers__c, Submitted_Date__c, Manufacturing_Site__c,
                        CMPL123CME__Catalogue_Number__c, CMPL123CME__Lot_Numbers__c, CMPL123CME__SubmitterCountry__c, Waived_Rationale__c,
                        CMPL123CME__Complaint__c
                 FROM CMPL123CME__MEDDEV__c
                 WHERE CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c IN :ids]
            );
            //@Lakshman
            Map <Id, List <CMPL123CME__EU_MIR__c>> eumirByTicket = 
            GroupBy.id(
                'CMPL123CME__Complaint__c',
                [SELECT Id,Name,CMPL123CME__Manufacturer_S_Reference_Number__c,Submitted_Date__c,
                CMPL123CME__Registered_Commercial_Name_Of_Company__c,
                CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c, CMPL123CME__Catalogue_Reference_Number__c,
                CMPL123CME__Lot_Batch_Numbers__c, Registerd_Site_Name__c, 
                Waived_Rationale__c, Country__c, Country__r.Name, Submission_Type__c, Submission_Type__r.Name,CMPL123CME__Reference_Number_By_Manufacturer__c, 
                CMPL123CME__Type_of_Report__c,CMPL123CME__Complaint__c, CMPL123CME__Submitter_Of_Report__c, CMPL123CME__Initial_Reporter_Country__c
                 FROM CMPL123CME__EU_MIR__c
                 WHERE CMPL123CME__Complaint__r.CMSNext_Ticket_Number__c IN :ids]
            );
        for (CMPL123CME__Complaint__c objComplaint : ticketsList) {
            ComplaintTicketReportResult ctr = new ComplaintTicketReportResult();
            if (objComplaint.CMPL123CME__Customer__r != null) {
                objComplaint.CMPL123CME__Customer__r.Name = LineSplitter.splitLines(objComplaint.CMPL123CME__Customer__r.Name, 14);
                objComplaint.CMPL123CME__Customer__r.City__c = LineSplitter.splitLines(objComplaint.CMPL123CME__Customer__r.City__c, 14);
                objComplaint.CMPL123CME__Customer__r.State__c = LineSplitter.splitLines(objComplaint.CMPL123CME__Customer__r.State__c, 14);
                objComplaint.CMPL123CME__Customer__r.Contact_Address_Line_1__c = LineSplitter.splitLines(objComplaint.CMPL123CME__Customer__r.Contact_Address_Line_1__c, 14);
                objComplaint.CMPL123CME__Customer__r.Contact_Address_Line_2__c = LineSplitter.splitLines(objComplaint.CMPL123CME__Customer__r.Contact_Address_Line_2__c, 14);
            }
            objComplaint.Ticket_Description__c = LineSplitter.splitLines(objComplaint.Ticket_Description__c, 14);
            ctr.ticketsList = new List<CMPL123CME__Complaint__c> { objComplaint };
            ticketIds.add(objComplaint.Id);
            ctr.attachmentIdSet.add(objComplaint.Id);
            if (productTicketsByTicket.containsKey(objComplaint.Id)) {
                ctr.productTickets = productTicketsByTicket.get(objComplaint.Id);
                for(Product_Ticket__c objProductEvents : ctr.productTickets) {
                    ctr.attachmentIdSet.add(objProductEvents.Id);
                }    
            }
            if (contactsByTicket.containsKey(objComplaint.Id)) {
                ctr.contacts = contactsByTicket.get(objComplaint.Id);
                for(Contact__c objContact : ctr.contacts) {
                    objContact.Name__c = LineSplitter.splitLines(objContact.Name__c, 14);
                    objContact.Occupation__c = LineSplitter.splitLines(objContact.Occupation__c, 14);
                    ctr.attachmentIdSet.add(objContact.Id);
                }
            }
            if (ticketNotesByTicket.containsKey(objComplaint.Id)) {
                ctr.ticketNotes = ticketNotesByTicket.get(objComplaint.Id);
                for(Ticket_Note__c objTicketNote : ctr.ticketNotes) {
                    objTicketNote.Ticket_Notes_Native__c = LineSplitter.splitLines(objTicketNote.Ticket_Notes_Native__c, 14);
                    ctr.attachmentIdSet.add(objTicketNote.Id);
                }
            }
            if (meaningfulDatasByTicket.containsKey(objComplaint.Id)) {
                ctr.meaningfulDatas = meaningfulDatasByTicket.get(objComplaint.Id);
                for(Meaningful_Data__c objMeaningFulData : ctr.meaningfulDatas) {
                    objMeaningFulData.Meaningful_Data_Answers__c = LineSplitter.splitLines(objMeaningFulData.Meaningful_Data_Answers__c, 14);
                    ctr.attachmentIdSet.add(objMeaningFulData.Id);
                }
            }
            if (activitiesByTicket.containsKey(objComplaint.Id)) {
                ctr.activities = activitiesByTicket.get(objComplaint.Id);
                for(Activity__c objActivity : ctr.activities) {
                    ctr.attachmentIdSet.add(objActivity.Id);
                }
            }
            if (customerResponsesByTicket.containsKey(objComplaint.Id)) {
                ctr.customerResponses = customerResponsesByTicket.get(objComplaint.Id);
                for(Customer_Response__c objCustomerResponse : ctr.customerResponses) {
                    //Original field is not writable (formula). Possibly deprecated one is used
                    objCustomerResponse.Additional_Reply_Expectation__c = LineSplitter.splitLines(objCustomerResponse.Additional_Reply_Expectation__c, 14);
                    ctr.attachmentIdSet.add(objCustomerResponse.Id);
                }
            }
            if (assessmentsByTicket.containsKey(objComplaint.Id)) {
                for(CMPL123CME__Questionnaire__c objQuestionnaire : assessmentsByTicket.get(objComplaint.Id)) {
                    ctr.attachmentIdSet.add(objQuestionnaire.Id);
                }
            }
            if (emdrsByTicket.containsKey(objComplaint.Id)) {
                for(CMPL123CME__EMDR__c objEmdr : emdrsByTicket.get(objComplaint.Id)) {
                    ctr.attachmentIdSet.add(objEmdr.Id);
                }
            }
            if (meddevsByTicket.containsKey(objComplaint.Id)) {
                for(CMPL123CME__MEDDEV__c objMeddev : meddevsByTicket.get(objComplaint.Id)) {
                    ctr.attachmentIdSet.add(objMeddev.Id);
                }
            }
            //@Lakshman
            if (eumirByTicket.containsKey(objComplaint.Id)) {
                for(CMPL123CME__EU_MIR__c objEumir : eumirByTicket.get(objComplaint.Id)) {
                    ctr.attachmentIdSet.add(objEumir.Id);
                }
            }
            result.put(objComplaint.Id, ctr);
        }
        //pRE Information details query.

        //Updated - W-000126 - 31/07/2018 - Query only "Y" answers
        Map<Id, List<pRE_Information__c> > pREInformationMap = 
            GroupBy.parentId(
                new string[] {'Complaint__r'}, 
                'Id', 
                [SELECT Id, Name, First_Use_of_the_Device__c, Alert_Flag_Error_Code_Alarm_Generate__c, Sample_Type_Storage_Condition__c,
                        Sample_Type_Storage_Condition_Tranls__c, Device_Storage_Condition__c, Device_Storage_Condition_Translated__c,
                        No_Patient_Information_Available__c, No_Patient_Result_Information_Available__c, Device_Expiration_Date__c, Complaint__r.Id,
                        (SELECT Id, Name, Question__c, Question_Category__c, Answer__c 
                         FROM pRE_Questions__r 
                         WHERE Answer__c = 'Y' 
                         ORDER BY CreatedDate DESC),
                        (SELECT Id, Name, Patient_Information__c, Patient_Information_Translated__c 
                         FROM Patient_Information__r)
                 FROM pRE_Information__c 
                 WHERE Complaint__c IN: ticketIds]);

        for (Id ticketId : result.keySet()) {
            if (pREInformationMap.containsKey(ticketId)) {
                ComplaintTicketReportResult ctr = result.get(ticketId);
                ctr.pREInformationChilds = pREInformationMap.get(ticketId);

                for(pRE_Information__c objpREInformation : ctr.pREInformationChilds) {
                    objpREInformation.Sample_Type_Storage_Condition_Tranls__c = LineSplitter.splitLines(objpREInformation.Sample_Type_Storage_Condition_Tranls__c, 14);
                    objpREInformation.Sample_Type_Storage_Condition__c = LineSplitter.splitLines(objpREInformation.Sample_Type_Storage_Condition__c, 14);
                    ctr.attachmentIdSet.add(objpREInformation.Id);

                    if(''+objpREInformation.pRE_Questions__r != '' || ''+objpREInformation.pRE_Questions__r != null) {
                        for(pRE_Question__c objpREQuestion : objpREInformation.pRE_Questions__r) {
                            ctr.attachmentIdSet.add(objpREQuestion.Id);
                            objpREQuestion.Question_Category__c = objpREQuestion.Question_Category__c != null ? objpREQuestion.Question_Category__c : 'No Category';

                            if(!ctr.preQuestionsCategoryMap.containsKey(objpREQuestion.Question_Category__c)) {
                                ctr.preQuestionsCategoryMap.put(objpREQuestion.Question_Category__c, New List<pRE_Question__c> {objpREQuestion});
                            } else{
                                ctr.preQuestionsCategoryMap.get(objpREQuestion.Question_Category__c).add(objpREQuestion);
                            }
                        }
                    } else {
                    }
                    for(Patient_Information__c objPatientInformation : objpREInformation.Patient_Information__r) {
                        objPatientInformation.Patient_Information__c = LineSplitter.splitLines(objPatientInformation.Patient_Information__c, 14);
                        ctr.attachmentIdSet.add(objPatientInformation.Id);
                    }
                }

            }
        }

        Map<Id, List<Ticket_Product_Evaluation_Investigation__c> > ticketPEMap = 
            GroupBy.id(
                'Ticket__c', 
                [SELECT Id, Investigation_Evaluation__c, Investigation_Evaluation__r.Name, Investigation_Evaluation__r.Id,
                        Investigation_Evaluation__r.Assessor__r.Name, Investigation_Evaluation__r.Evaluator_Investigator__r.Name,
                        Investigation_Evaluation__r.Approver__r.Name, Type__c, Ticket__c, Investigation_Evaluation__r.Products__c,
                        Investigation_Evaluation__r.Product_Lot_Numbers__c, Investigation_Evaluation__r.Product_List_Numbers__c,
                        Investigation_Evaluation__r.Device_Manufacturing_Date__c, Investigation_Evaluation__r.Device_Expiration_Date__c,
                        Investigation_Evaluation__r.If_No_Explain__c, Investigation_Evaluation__r.Complaint_Summary__c,
                        Investigation_Evaluation__r.Conclusion_Disposition__c, Investigation_Evaluation__r.Not_Requested_Rationale__c,
                        Investigation_Evaluation__r.CMPL123_WF_Status__c,Investigation_Evaluation__r.Is_Investigation_Required__c,
                        Investigation_Evaluation__r.No_Investigation_Rationale__c, Investigation_Evaluation__r.Evaluation_Investigation_Group__c,
                        Investigation_Evaluation__r.Prod_Eval_Returns_to_be_Requested__c,
                        Investigation_Evaluation__r.Conclusion_Summary__c,Investigation_Evaluation__r.Additional_Action_Taken__c,
                        Investigation_Evaluation__r.Describe_Additional_Action_Taken__c, Investigation_Evaluation__r.Evaluator_Investigator__c,
                        Investigation_Evaluation__r.Approver__c, Investigation_Evaluation__r.Approval_Date__c,
                        Investigation_Evaluation__r.CAPA_Reference__c,Investigation_Evaluation__r.CAPA_Wavier_Rationale__c,
                        Investigation_Evaluation__r.Diagnostic_Use__c
                 FROM Ticket_Product_Evaluation_Investigation__c
                 WHERE Ticket__c IN: ticketIds]);

        Map<Id, List<Product_Lot__c>> productsLotsMap = 
            GroupBy.parentId(
                new String[] {'Product_Evaluation_Investigation__r'}, 
                'CMPL123CME__Complaint__c', 
                [SELECT Id, Device_Expiration_Date__c, Device_Expiration_Date_NA__c, Device_Expiration_Date_Unknown__c,
                        Device_Manufacturing_Date__c, Device_Manufacturing_Date_NA__c, Device_Manufacturing_Date_Unknown__c,
                        Product_Evaluation_Investigation__r.CMPL123CME__Complaint__c
                 FROM Product_Lot__c
                 WHERE Product_Evaluation_Investigation__r.CMPL123CME__Complaint__c IN :ticketPEMap.keySet()]);

        Map<Id, List<Task_Product_Evaluation_Investigation__c> > tasksMap =
            GroupBy.parentId(
                new string[] {'Investigation_Evaluation__r'}, 
                'CMPL123CME__Complaint__c', 
                [SELECT Id, Investigation_Evaluation__c, Task__c, Task__r.Id, Task__r.Task_Instructions1__c, Task__r.RecordType.Name,
                        Task__r.Conclusion__c, Task__r.Result__c, Investigation_Evaluation__r.CMPL123CME__Complaint__c
                 FROM Task_Product_Evaluation_Investigation__c
                 WHERE Investigation_Evaluation__r.CMPL123CME__Complaint__c IN: ticketIds]);

        for (Id ticketId : result.keySet()) {
            ComplaintTicketReportResult ctr = result.get(ticketId);
            ctr.productsLotsMap = new Map<Id, List<Product_Lot__c>> ();
            if (productsLotsMap.containsKey(ticketId)) {
                ctr.productsLotsMap.put(ticketId, productsLotsMap.get(ticketId));
            } else {
            }
            Map<Id, List<Task_Product_Evaluation_Investigation__c> > peTasksMap = new Map<Id, List<Task_Product_Evaluation_Investigation__c> >();
            if (tasksMap.containsKey(ticketId)) {
                List<Task_Product_Evaluation_Investigation__c> tasksList = tasksMap.get(ticketId);
                peTasksMap = GroupBy.id('Investigation_Evaluation__c', tasksList);
                for(Task_Product_Evaluation_Investigation__c objTaskProductEvaluationInvestigation : tasksList) {
                    ctr.attachmentIdSet.add(objTaskProductEvaluationInvestigation.Id);
                    ctr.attachmentIdSet.add(objTaskProductEvaluationInvestigation.Task__r.Id);
                }
            } else {
            }

            if (ticketPEMap.containsKey(ticketId)) {
                ctr.prodEvalsList = new List<TicketProdEvalWrapper>();
                for(Ticket_Product_Evaluation_Investigation__c tpe: ticketPEMap.get(ticketId)) {
                    TicketProdEvalWrapper tpeWrapper = new TicketProdEvalWrapper();
                    tpeWrapper.obj = tpe;
                    if(tpe.Investigation_Evaluation__c != null && peTasksMap.containsKey(tpe.Investigation_Evaluation__c)) {
                        tpeWrapper.tasks = peTasksMap.get(tpe.Investigation_Evaluation__c);
                    } else {
                        tpeWrapper.tasks = new List<Task_Product_Evaluation_Investigation__c>();
                    }
                    ctr.prodEvalsList.add(tpeWrapper);
                    ctr.attachmentIdSet.add(tpe.Investigation_Evaluation__r.Id);
                }
            } else {
            }
        }

        //Updated - W-000126 - 06/08/2018 - adding med eval
        // 17-Sep-2021 Larry R: Tip to other devs: If the Visualforce page 
        // crashes due to retrieving a non-queried field from SOQL, make sure this inner
        // query gets the same fields as the Map-of-Lists that was defined beforehand
        Map<Id, List<CMPL123CME__Questionnaire__c> > medEvalWithQuestionsMap = 
            GroupBy.id(
                'CMPL123CME__Complaint__c', 
                [SELECT Id, Name, CMPL123CME__Complaint__c, Initial_Awareness_Date__c, Submitted_Date__c, Follow_Up_Awareness_Date__c,
                 Agency__c, Reportability_Date__c, Reportability_Category__c, Reportability__c, pRE_Status__c, Adverse_Event__c,
                 Field_Action_Number__c, Reportability_Rationale__c,
                 (SELECT Id, Name, CMPL123CME__Questionnaire__c, CMPL123CME__Answer__c, CMPL123CME__Question__c,
                         CMPL123CME__Question_No__c, Reportability__c 
                  FROM CMPL123CME__Questionnaire_Items__r),
                 (SELECT Name, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__G8_MFR_Report_Number__c, RecordType.Name,
                         Classification__c, CMPL123CME__Submitted_Date_Time__c, Report_Submitter__c, Registered_Site_Name__c,
                         E1_Country_New__c, CMPL123CME__D1_Brand_Name__c, CMPL123CME__D4_Catalog_No__c,Submission_Type__c,
                  //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c" and also added "D4_Primary_UDI_Unique_Identifier__c".
                         //CMPL123CME__D4_Serial_No__c, CMPL123CME__D4_Lot_No__c, CMPL123CME__Unique_Identifier_UDI__c,CMPL123CME__MFR_Report_Ref__c,
                         CMPL123CME__D4_Serial_No__c, CMPL123CME__D4_Lot_No__c, CMPL123CME__D4_Primary_UDI_Number__c, D4_Primary_UDI_Unique_Identifier__c, CMPL123CME__MFR_Report_Ref__c,
                         Void_Rational__c
                  FROM EMDR__r 
                  ORDER BY CMPL123CME__CMPL123_WF_Status__c),
                 (SELECT Id,Name,CMPL123CME__Manufacturer_Reference_Number__c,Submitted_Date_new__c,
                         CMPL123CME__HealthcareCountry__c, CMPL123CME__Submitter_Name__c, CMPL123CME__Commercial_Name__c,
                         CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c, CMPL123CME__Catalogue_Number__c,
                         CMPL123CME__Lot_Numbers__c, Registered_Site_Name__c, CMPL123CME__SubmitterCountry__c,
                         Report_Submitter__c, Waived_Rationale__c, Country__c, Country__r.Name, Submission_Type__c,
                         RecordType.Name,CMPL123CME__Type_of_Report__c
                  FROM MDI__r 
                  ORDER BY CMPL123_WF_Status__c),
                  //@Lakshman
                  //@Juneid 17 Sep 2021, Added new filed 
                  (SELECT Id,Name,CMPL123CME__Manufacturer_S_Reference_Number__c,CMPL123CME__Reference_Number_By_Manufacturer__c,Submitted_Date__c,
                  CMPL123CME__Registered_Commercial_Name_Of_Company__c,
                  CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c, CMPL123CME__Catalogue_Reference_Number__c,
                  CMPL123CME__Lot_Batch_Numbers__c, Registerd_Site_Name__c, 
                  Waived_Rationale__c, Country__c, Country__r.Name, Submission_Type__c, Submission_Type__r.Name, 
                  CMPL123CME__Type_of_Report__c, CMPL123CME__Submitter_Of_Report__c, CMPL123CME__Initial_Reporter_Country__c
                  FROM EU_MIR__r 
                  ORDER BY CMPL123_WF_Status__c)
                FROM CMPL123CME__Questionnaire__c 
                WHERE CMPL123CME__Complaint__c IN: ticketIds]);
 
        for (Id ticketId : result.keySet()) {

            if (medEvalWithQuestionsMap.containsKey(ticketId)) {
                ComplaintTicketReportResult ctr = result.get(ticketId);
                ctr.medEvalWithQuestionsList = medEvalWithQuestionsMap.get(ticketId);
                for(CMPL123CME__Questionnaire__c objQuestionnaire : ctr.medEvalWithQuestionsList) {

                    ctr.attachmentIdSet.add(objQuestionnaire.Id);

                    for(CMPL123CME__EMDR__c objEMDR : objQuestionnaire.EMDR__r) {
                        if(objEMDR.CMPL123CME__CMPL123_WF_Status__c != '' || objEMDR.CMPL123CME__CMPL123_WF_Status__c != null) {
                            if(!ctr.emdrStatusMap.containsKey(objEMDR.CMPL123CME__CMPL123_WF_Status__c)) {
                                ctr.emdrStatusMap.put(objEMDR.CMPL123CME__CMPL123_WF_Status__c, New List<CMPL123CME__EMDR__c> {objEMDR});
                                ctr.attachmentIdSet.add(objEMDR.Id);
                            }else{
                                ctr.emdrStatusMap.get(objEMDR.CMPL123CME__CMPL123_WF_Status__c).add(objEMDR);
                                ctr.attachmentIdSet.add(objEMDR.Id);
                            }
                        }
                    }

                    for(CMPL123CME__MEDDEV__c objMeddev : objQuestionnaire.MDI__r) {
                        if(objMeddev.CMPL123_WF_Status__c != '' || objMeddev.CMPL123_WF_Status__c != null) {
                            if(!ctr.medDevStatusMap.containsKey(objMeddev.CMPL123_WF_Status__c)) {
                                ctr.medDevStatusMap.put(objMeddev.CMPL123_WF_Status__c, New List<CMPL123CME__MEDDEV__c> {objMeddev});
                                ctr.attachmentIdSet.add(objMeddev.Id);
                            }else{
                                ctr.medDevStatusMap.get(objMeddev.CMPL123_WF_Status__c).add(objMeddev);
                                ctr.attachmentIdSet.add(objMeddev.Id);
                            }
                        }
                    }

                    //@Lakshman
                    for(CMPL123CME__EU_MIR__c objEumir : objQuestionnaire.EU_MIR__r) {
                        if(objEumir.CMPL123_WF_Status__c != '' || objEumir.CMPL123_WF_Status__c != null) {
                            if(!ctr.euMirStatusMap.containsKey(objEumir.CMPL123_WF_Status__c)) {
                                ctr.euMirStatusMap.put(objEumir.CMPL123_WF_Status__c, New List<CMPL123CME__EU_MIR__c> {objEumir});
                                ctr.attachmentIdSet.add(objEumir.Id);
                            }else{
                                ctr.euMirStatusMap.get(objEumir.CMPL123_WF_Status__c).add(objEumir);
                                ctr.attachmentIdSet.add(objEumir.Id);
                            }
                        }
                    }

                    for(CMPL123CME__Questionnaire_Items__c objQuestionnaireItems : objQuestionnaire.CMPL123CME__Questionnaire_Items__r) {
                        ctr.attachmentIdSet.add(objQuestionnaireItems.Id);
                    }

                }

            } else {
            }
        }
        //PMD report fix for SOQL in loop start. Creation of new map to use it insead of SOQL in loop.
        Map <Id, List<Attachment__c>> attachmentIdsByTicketId = new Map <Id, List<Attachment__c>>();
        List <Id> parentRecordIds = new List <Id>();
        for (Id ticketId : result.keySet()) {
            ComplaintTicketReportResult ctr = result.get(ticketId);
            parentRecordIds.addAll(ctr.attachmentIdSet);
        }
        //HC Defect #44 fix BEGIN: Big query divided into 12 small queries because of iterator issue.
        List <Attachment__c> objAttachments = new List <Attachment__c> ();
        String queryStatement = 'SELECT Id, Name, Attachment_Title__c, Attachment_Type__c, Attachment_Description__c, UNC_Path__c, Customer_Response__c'
                                + ' , Customer_Response_Master__c, EMDR__c, Evaluation_Investigation_Task__c, Investigation_Evaluation__c, MEDDEV__c,EU_MIR__c'
                                + ' , Assessment__c, Medical_Evaluation_Task__c, Regulatory_Task__c, Return__c, Ticket__c, Tracking_Trending_Review_Task__c'
                                + ' FROM Attachment__c WHERE ';
        String inStatement = 'IN :parentRecordIds';
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'EMDR__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Evaluation_Investigation_Task__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Investigation_Evaluation__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'MEDDEV__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'EU_MIR__c ' + inStatement));//@Lakshman
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Assessment__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Medical_Evaluation_Task__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Regulatory_Task__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Return__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Ticket__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Tracking_Trending_Review_Task__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Customer_Response_Master__c ' + inStatement));
        objAttachments.addAll((List <Attachment__c>) Database.query(queryStatement + 'Customer_Response__c ' + inStatement));
        //HC Defect #44 fix END
        for (Id ticketId : result.keySet()) {
            ComplaintTicketReportResult ctr = result.get(ticketId);
            for (Attachment__c objAttachment: objAttachments) {
                if (ctr.attachmentIdSet.contains(objAttachment.Customer_Response__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Customer_Response_Master__c)
                    || ctr.attachmentIdSet.contains(objAttachment.EMDR__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Evaluation_Investigation_Task__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Investigation_Evaluation__c)
                    || ctr.attachmentIdSet.contains(objAttachment.MEDDEV__c)
                    || ctr.attachmentIdSet.contains(objAttachment.EU_MIR__c)//@Lakshman
                    || ctr.attachmentIdSet.contains(objAttachment.Assessment__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Medical_Evaluation_Task__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Regulatory_Task__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Return__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Ticket__c)
                    || ctr.attachmentIdSet.contains(objAttachment.Tracking_Trending_Review_Task__c)) {
                        if (attachmentIdsByTicketId.containsKey(ticketId)) {
                            attachmentIdsByTicketId.get(ticketId).add(objAttachment);
                        } else {
                            attachmentIdsByTicketId.put(ticketId, new List <Attachment__c>{objAttachment});
                        }
                }
            }
        }
        //PMD report fix for SOQL in loop end.
        for (Id ticketId : result.keySet()) {
            ComplaintTicketReportResult ctr = result.get(ticketId);
            //PMD report fix for SOQL in loop start. Added condition and replaced inner SOQL with map.
            if (attachmentIdsByTicketId.containsKey(ticketId)) {
                for(Attachment__c objAttachment : attachmentIdsByTicketId.get(ticketId)) {
                    //PMD report fix for SOQL in loop end.
                    if (String.isNotBlank(objAttachment.Customer_Response__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Customer_Response__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Customer_Response_Master__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Customer_Response_Master__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.EMDR__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.EMDR__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Evaluation_Investigation_Task__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Evaluation_Investigation_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Investigation_Evaluation__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Investigation_Evaluation__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.MEDDEV__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.MEDDEV__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.EU_MIR__c)) {//@Lakshman
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.EU_MIR__c.getSObjectType().getDescribe().getName()})[0].getLabel();    
                    } else if(String.isNotBlank(objAttachment.Assessment__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Assessment__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Medical_Evaluation_Task__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Medical_Evaluation_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Regulatory_Task__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Regulatory_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Return__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Return__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Ticket__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Ticket__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else if(String.isNotBlank(objAttachment.Tracking_Trending_Review_Task__c)) {
                        objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String> {objAttachment.Tracking_Trending_Review_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                    } else {
                    }

                    ctr.attachmentList.add(objAttachment);

                }
            }
        }
        return result.values();
    }
}