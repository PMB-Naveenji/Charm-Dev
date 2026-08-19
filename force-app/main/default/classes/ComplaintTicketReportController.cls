/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ComplaintTicketReportController
* @Why   : It shows the all the child propertyes in VF page  .
* @When  : 23-03-2017
* @Where : It Acts like a utility class  
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    23-03-2017             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
   Lakshman               03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G7_Type_of_Report_MultiSelect__c -> CMPL123CME__G6_Type_of_Report__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*   Sameer                 09-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__G9_MFR_Report_Number__c -> CMPL123CME__G8_MFR_Report_Number__c
* ---------------------------------------------------------------------------------------------------------------------------------------
    Dinesh Kumar           15-JAN-2024            CHaRM-R4             Updated the method "ComplaintTicketReportController"
* ---------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ComplaintTicketReportController {
    
    public List<CMPL123CME__Complaint__c> ticketWithChildsList{get;set;}
    public List<pRE_Information__c> pREInformationChilds{get;set;}
    public List<Customer_Response__c> customerResponses{get;set;}
    public List<TicketProdEvalWrapper> prodEvalsList{get;set;}
    public List<CMPL123CME__Questionnaire__c> medEvalWithQuestionsList{get;set;}

    public class TicketProdEvalWrapper {
        public Ticket_Product_Evaluation_Investigation__c obj { get; set; }
        public List<Task_Product_Evaluation_Investigation__c> tasks { get; set; }
        
        public TicketProdEvalWrapper() {
            obj = new Ticket_Product_Evaluation_Investigation__c();
            tasks = new List<Task_Product_Evaluation_Investigation__c>();
        }
    }
    
    // Code change
    public Map<String, List<pRE_Question__c>> preQuestionsCategoryMap{get;set;}
    public Map<String, List<CMPL123CME__EMDR__c>> emdrStatusMap{get;set;}
    public Map<String, List<CMPL123CME__MEDDEV__c>> medDevStatusMap{get;set;}
    public Map<String, List<CMPL123CME__EU_MIR__c>> euMirStatusMap{get;set;}//@Lakshman
    
    public Integer emdrStatusMapSize { get { return emdrStatusMap.size(); } }
    public Integer medDevStatusMapSize { get { return medDevStatusMap.size(); } }
    public Integer euMirStatusMapSize { get { return euMirStatusMap.size(); } }//@Lakshman
    public Integer preQuestionsCategoryMapSize { get { return preQuestionsCategoryMap.size(); } }
    
    public Set<Id> attachmentIdSet {get;set;}
    public List<Attachment__c> attachmentList {get;set;}
    
    String ticketId = ApexPages.CurrentPage().getparameters().get('id');

    /**
    * @Method       : ComplaintTicketReportController
    * @Invoke       : It invokes in Vf Page 
    * @Description  : It show all the child class propertyes 
    * @Return       : ComplaintTicketReportController Constractor 
    * @Params       : ApexPages.StandardController controller
    **/
    public ComplaintTicketReportController(ApexPages.StandardController controller) {
        
        preQuestionsCategoryMap = new Map<String, List<pRE_Question__c>>();
        emdrStatusMap = new Map<String, List<CMPL123CME__EMDR__c>>();
        medDevStatusMap = new Map<String, List<CMPL123CME__MEDDEV__c>>();
        euMirStatusMap = new Map<String, List<CMPL123CME__EU_MIR__c>>();//@Lakshman
        attachmentIdSet = new Set<Id>();
        attachmentList = new List<Attachment__c>();
        
        ticketWithChildsList = [SELECT Id, CMPL123CME__Customer__r.Name, Customer_Name_Translated__c, Ticket_origination_Date__c, 
                                Country_of_origin__c, Product_Evaluation_Start_Date__c, Investigation_Status__c, Registration_Ticket_Owner__c, 
                                CMPL123CME__Customer__r.Contact_Address_Line_1__c, 
                                CMPL123CME__Customer__r.Contact_Address_Line_2__c, Division__c, Receipt_Date__c, Ticket_Close_Date__c,
                                Description_Translated__c,pRE_Status__c, Investigation_Conclusion__c,Overall_Reportable_Status__c, Was_an_Adverse_Event_Identified__c,
                                Ticket_Description__c,Error_code__c, Experience_code__c,Trending_Experience_Bucket__c,
                                Quality_Directive_Number__c, Quality_Directive_Revision__c, CMSNext_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c,
                                Returns_Available__c,Description_of_Available_Returns__c,Registration_Ticket_Number__c,CMPL123CME__Customer__r.City__c,
                                CMPL123CME__Customer__r.State__c,CMPL123CME__Customer__r.Zip_Postal_Code__c,CMPL123CME__Customer__r.Country__c,
                                
                                (SELECT Id,Likely_Cause__c,Product_Name__c,Product_List_Number__c ,Batch_Lot_Serial__c FROM Products_Events__r),
                                
                                //Updated - W-000126 - 31/07/2018 - Query only Primary Contacts 
                                (SELECT Id,Name,Name__c, Contact_Name_Translated__c,Contact_Phone_Number__c,Occupation__c,
                                 Contact_Occupation_Translated__c FROM Related_Contact__r WHERE Primary__c = true),
                                
                                (SELECT Id, Ticket_Notes_Created_By__c,Ticket_Notes_Created_Date__c,Ticket_Notes_Native__c,
                                 Ticket_Notes_Translated__c FROM Ticket_Notes__r), 
                                
                                (SELECT Id, Mean__c,Meaningful_Data_Answers__c, Meaningful_data_Answer_Translated__c FROM Meaningful_Data__r),
                                
                                (SELECT Id,Work_Done_Code__c, Work_Done_Code_Description__c,Work_Done_Likely_Cause__c, Performed_By__c 
                                 FROM Activities__r),
                                
                                (SELECT Id, Name, Customer_Expectation__c,New_Customer_Expectation__c, Customer_Reply__c, Customer_Expectation_Translated__c, 
                                 Additional_Reply_Expectation_Translated__c, Additional_Reply_Expectation__c, Event__c 
                                 FROM Customer_Responses__r) ,
                                
                                (SELECT Id,Initial_Awareness_Date__c,Follow_Up_Awareness_Date__c,Agency__c,Submitted_Date__c, Reportability__c,
                                 Reportability_Date__c, Adverse_Event__c, Reportability_Category__c, Field_Action_Flag__c, pRE_Status__c, 
                                 Field_Action_Number__c FROM CMPL123CME__Questionnaires__r),
                                //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c" and also added "D4_Primary_UDI_Unique_Identifier__c".
                                (SELECT Id,CMPL123CME__Submitted_Date_Time__c,E1_Country1__c,CMPL123CME__E1_Country__c,Name,
                                 CMPL123CME__D1_Brand_Name__c,CMPL123CME__D4_Serial_No__c, CMPL123CME__EMDR_MFR__c,
                                 Classification__c,CMPL123CME__Submitted_By__c,CMPL123CME__D4_Catalog_No__c, CMPL123CME__CMPL123_WF_Status__c,
                                 CMPL123CME__D4_Lot_No__c,CMPL123CME__G1_Mfg_Name__c,CMPL123CME__G8_MFR_Report_Number__c, 
                                 CMPL123CME__G6_Type_of_Report__c, CMPL123CME__D4_Primary_UDI_Number__c, D4_Primary_UDI_Unique_Identifier__c,
                                 CMPL123CME__MFR_Report_Ref__c,Submission_Type__c
                                 FROM CMPL123CME__EMDR__r),
                                
                                (SELECT Id,CMPL123CME__Manufacturer_Reference_Number__c,CMPL123CME__Submitter_Name__c, CMPL123CME__Commercial_Name__c, 
                                 CMPL123CME__HealthcareCountry__c, CMPL123CME__Serial_Numbers__c, Submitted_Date__c,Manufacturing_Site__c,
                                 CMPL123CME__Catalogue_Number__c,CMPL123CME__Lot_Numbers__c, CMPL123CME__SubmitterCountry__c,Waived_Rationale__c 
                                 FROM CMPL123CME__MEDDEV__r),
                                //@Lakshman
                                (SELECT Id,Name,CMPL123CME__Manufacturer_S_Reference_Number__c,CMPL123CME__Date_Of_Submission__c,
                                CMPL123CME__Registered_Commercial_Name_Of_Company__c, CMPL123CME__Initial_Reporter_Country__c,
                                CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c, CMPL123CME__Catalogue_Reference_Number__c,
                                CMPL123CME__Lot_Batch_Numbers__c, Registerd_Site_Name__c, 
                                Waived_Rationale__c, Country__c, Country__r.Name, Submission_Type__c, CMPL123CME__Submitter_Of_Report__c, Submission_Type__r.Name
                                 FROM CMPL123CME__EU_MIR__r)
                                
                                FROM CMPL123CME__Complaint__c WHERE ID =: ticketId];
        
        for(CMPL123CME__Complaint__c objComplaint : 
            [SELECT Id, 
             (SELECT Id FROM Products_Events__r),
             (SELECT Id FROM Related_Contact__r WHERE Primary__c = true),
             (SELECT Id FROM Ticket_Notes__r),
             (SELECT Id FROM Meaningful_Data__r),
             (SELECT Id FROM Activities__r),
             (SELECT Id FROM Customer_Responses__r),
             (SELECT Id FROM CMPL123CME__Questionnaires__r),
             (SELECT Id FROM CMPL123CME__EMDR__r),
             (SELECT Id FROM CMPL123CME__MEDDEV__r),
             (SELECT Id FROM CMPL123CME__EU_MIR__r)//@Lakshman
             
             FROM CMPL123CME__Complaint__c WHERE ID =: ticketId]) {
                 
                 attachmentIdSet.add(objComplaint.Id);
                 for(Product_Ticket__c objProductEvents : objComplaint.Products_Events__r) {
                     attachmentIdSet.add(objProductEvents.Id);
                 }
                 for(Contact__c objContact : objComplaint.Related_Contact__r) {
                     attachmentIdSet.add(objContact.Id);
                 }
                 for(Ticket_Note__c objTicketNote : objComplaint.Ticket_Notes__r) {
                     attachmentIdSet.add(objTicketNote.Id);
                 }
                 for(Meaningful_Data__c objMeaningFulData : objComplaint.Meaningful_Data__r) {
                     attachmentIdSet.add(objMeaningFulData.Id);
                 }
                 for(Activity__c objActivity : objComplaint.Activities__r){
                     attachmentIdSet.add(objActivity.Id);
                 }
                 for(Customer_Response__c objCustomerResponse : objComplaint.Customer_Responses__r) {
                     attachmentIdSet.add(objCustomerResponse.Id);
                 }
                 for(CMPL123CME__Questionnaire__c objQuestionnaire : objComplaint.CMPL123CME__Questionnaires__r) {
                     attachmentIdSet.add(objQuestionnaire.Id);
                 }
                 for(CMPL123CME__EMDR__c objEmdr : objComplaint.CMPL123CME__EMDR__r) {
                     attachmentIdSet.add(objEmdr.Id);
                 }
                 for(CMPL123CME__MEDDEV__c objMeddev : objComplaint.CMPL123CME__MEDDEV__r) {
                     attachmentIdSet.add(objMeddev.Id);
                 }
                 for(CMPL123CME__EU_MIR__c objEumir : objComplaint.CMPL123CME__EU_MIR__r) {
                    attachmentIdSet.add(objEumir.Id);
                }
             }
        //pRE Information details query.
        
        //Updated - W-000126 - 31/07/2018 - Query only "Y" answers 
        pREInformationChilds =  [SELECT Id, Name, First_Use_of_the_Device__c, Alert_Flag_Error_Code_Alarm_Generate__c, Sample_Type_Storage_Condition__c, 
                                 Sample_Type_Storage_Condition_Tranls__c, Device_Storage_Condition__c, Device_Storage_Condition_Translated__c, 
                                 No_Patient_Information_Available__c, No_Patient_Result_Information_Available__c, Device_Expiration_Date__c,
                                 (SELECT Id, Name, Question_Category__c, Answer__c FROM pRE_Questions__r WHERE Answer__c = 'Y' ORDER BY CreatedDate DESC),
                                 (SELECT Id, Name, Patient_Information__c, Patient_Information_Translated__c FROM Patient_Information__r)
                                 FROM pRE_Information__c WHERE Complaint__c =: ticketId ];
        
        for(pRE_Information__c objpREInformation : 
            [SELECT Id, Name, First_Use_of_the_Device__c, Alert_Flag_Error_Code_Alarm_Generate__c, Sample_Type_Storage_Condition__c, 
             Sample_Type_Storage_Condition_Tranls__c, Device_Storage_Condition__c, Device_Storage_Condition_Translated__c, 
             No_Patient_Information_Available__c, No_Patient_Result_Information_Available__c, Device_Expiration_Date__c,
             (SELECT Id, Name, Question_Category__c, Answer__c FROM pRE_Questions__r WHERE Answer__c = 'Y' ORDER BY CreatedDate DESC),
             (SELECT Id, Name, Patient_Information__c, Patient_Information_Translated__c FROM Patient_Information__r)
             FROM pRE_Information__c WHERE Complaint__c =: ticketId ]) {
                 
                 attachmentIdSet.add(objpREInformation.Id);
                 
                 if(''+objpREInformation.pRE_Questions__r != '' || ''+objpREInformation.pRE_Questions__r != null) {
                     for(pRE_Question__c objpREQuestion : objpREInformation.pRE_Questions__r) {
                         attachmentIdSet.add(objpREQuestion.Id);
                         objpREQuestion.Question_Category__c = objpREQuestion.Question_Category__c != null ? objpREQuestion.Question_Category__c : 'No Category';
                         
                         if(!preQuestionsCategoryMap.containsKey(objpREQuestion.Question_Category__c)){
                             preQuestionsCategoryMap.put(objpREQuestion.Question_Category__c, New List<pRE_Question__c>{objpREQuestion}); 
                         }else{
                             preQuestionsCategoryMap.get(objpREQuestion.Question_Category__c).add(objpREQuestion);   
                         }
                     }
                 }
                 
                 for(Patient_Information__c objPatientInformation : objpREInformation.Patient_Information__r) {
                     attachmentIdSet.add(objPatientInformation.Id);
                 }
                 
             }
        
        List<Ticket_Product_Evaluation_Investigation__c> ticketPEList = [SELECT Id, Investigation_Evaluation__c, Investigation_Evaluation__r.Name, Investigation_Evaluation__r.Id,
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
                         Investigation_Evaluation__r.CAPA_Reference__c,Investigation_Evaluation__r.CAPA_Wavier_Rationale__c  
                         FROM Ticket_Product_Evaluation_Investigation__c 
                         WHERE Ticket__c =: ticketId];
        
        for(Ticket_Product_Evaluation_Investigation__c objTicketProductEvaluationInvestigation : 
            [SELECT Id, Investigation_Evaluation__r.Name, Investigation_Evaluation__r.Id 
             FROM Ticket_Product_Evaluation_Investigation__c 
             WHERE Ticket__c =: ticketId]) {
                 attachmentIdSet.add(objTicketProductEvaluationInvestigation.Investigation_Evaluation__r.Id);
             }
        
        Map<Id, List<Task_Product_Evaluation_Investigation__c>> peTasksMap = new Map<Id, List<Task_Product_Evaluation_Investigation__c>>();
        List<Task_Product_Evaluation_Investigation__c> tasksList = new List<Task_Product_Evaluation_Investigation__c>();        
        for(Task_Product_Evaluation_Investigation__c peTask: [SELECT Id, Investigation_Evaluation__c, Task__c, Task__r.Task_Instructions1__c, Task__r.RecordType.Name,
                     Task__r.Conclusion__c, Task__r.Result__c
                     FROM Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__r.CMPL123CME__Complaint__c =: ticketId
                     AND Task__r.CMPL123_WF_Status__c != 'Closed-Done']) {
                         if(!peTasksMap.containsKey(peTask.Investigation_Evaluation__c)){
                             peTasksMap.put(peTask.Investigation_Evaluation__c, New List<Task_Product_Evaluation_Investigation__c>{peTask});
                         }else{
                             peTasksMap.get(peTask.Investigation_Evaluation__c).add(peTask); 
                         }        
        }
        
        prodEvalsList = new List<TicketProdEvalWrapper>();
        for(Ticket_Product_Evaluation_Investigation__c tpe: ticketPEList) {
            TicketProdEvalWrapper tpeWrapper = new TicketProdEvalWrapper();
            tpeWrapper.obj = tpe;
            if(tpe.Investigation_Evaluation__c != null && 
               peTasksMap.containsKey(tpe.Investigation_Evaluation__c)) {
                tpeWrapper.tasks = peTasksMap.get(tpe.Investigation_Evaluation__c);
            } else {
                tpeWrapper.tasks = new List<Task_Product_Evaluation_Investigation__c>();
            }
            prodEvalsList.add(tpeWrapper);
        }
        
        for(Task_Product_Evaluation_Investigation__c objTaskProductEvaluationInvestigation : 
            [SELECT Id, Task__r.Id FROM Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__r.CMPL123CME__Complaint__c =: ticketId
             AND Task__r.CMPL123_WF_Status__c != 'Closed-Done']) {
                 attachmentIdSet.add(objTaskProductEvaluationInvestigation.Id);
                 attachmentIdSet.add(objTaskProductEvaluationInvestigation.Task__r.Id);
             }
        
        //Updated - W-000126 - 06/08/2018 - adding med eval
        
        medEvalWithQuestionsList = [SELECT Id, CMPL123CME__Complaint__c, Initial_Awareness_Date__c, Submitted_Date__c, Follow_Up_Awareness_Date__c,  
                                    Agency__c, Reportability_Date__c, Reportability_Category__c, Reportability__c, pRE_Status__c, Adverse_Event__c, 
                                    Field_Action_Number__c, Reportability_Rationale__c,
                                    
                                    (SELECT Id, CMPL123CME__Questionnaire__c, CMPL123CME__Answer__c, CMPL123CME__Question__c, 
                                     CMPL123CME__Question_No__c, Reportability__c FROM CMPL123CME__Questionnaire_Items__r), 
                                   //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c" and also "D4_Primary_UDI_Unique_Identifier__c". 
                                    (SELECT Name, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__G8_MFR_Report_Number__c, RecordType.Name, 
                                      Classification__c, CMPL123CME__Submitted_Date_Time__c, Report_Submitter__c, Registered_Site_Name__c, 
                                      E1_Country_New__c, CMPL123CME__D1_Brand_Name__c, CMPL123CME__D4_Catalog_No__c,Submission_Type__c, 
                                      CMPL123CME__D4_Serial_No__c, CMPL123CME__D4_Lot_No__c, CMPL123CME__D4_Primary_UDI_Number__c, D4_Primary_UDI_Unique_Identifier__c
                                      FROM EMDR__r ORDER BY CMPL123CME__CMPL123_WF_Status__c),
                                    
                                    (SELECT Id,Name,CMPL123CME__Manufacturer_Reference_Number__c,Submitted_Date_new__c,
                                     CMPL123CME__HealthcareCountry__c, CMPL123CME__Submitter_Name__c, CMPL123CME__Commercial_Name__c,
                                     CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c, CMPL123CME__Catalogue_Number__c,
                                     CMPL123CME__Lot_Numbers__c, Registered_Site_Name__c, CMPL123CME__SubmitterCountry__c,
                                     Report_Submitter__c, Waived_Rationale__c, Country__c, Country__r.Name, Submission_Type__c,
                                     RecordType.Name,CMPL123CME__Type_of_Report__c 
                                     FROM MDI__r ORDER BY CMPL123_WF_Status__c),

                                     (SELECT Id,Name,CMPL123CME__Manufacturer_S_Reference_Number__c,CMPL123CME__Date_Of_Submission__c,
                                     CMPL123CME__Registered_Commercial_Name_Of_Company__c,
                                     CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c, CMPL123CME__Catalogue_Reference_Number__c,
                                     CMPL123CME__Lot_Batch_Numbers__c, Registerd_Site_Name__c, CMPL123CME__Initial_Reporter_Country__c,
                                     Waived_Rationale__c, Country__c, Country__r.Name, Submission_Type__c, Submission_Type__r.Name,                                  CMPL123CME__Type_of_Report__c, CMPL123CME__Submitter_Of_Report__c 
                                     FROM EU_MIR__r ORDER BY CMPL123_WF_Status__c)
                                    
                                    FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c =: ticketId];
        
        for(CMPL123CME__Questionnaire__c objQuestionnaire : 
            [SELECT Id,
             //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c" and also "D4_Primary_UDI_Unique_Identifier__c".
             (SELECT Name, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__G8_MFR_Report_Number__c, RecordType.Name, 
              Classification__c, CMPL123CME__Submitted_Date_Time__c, Report_Submitter__c, Registered_Site_Name__c, 
              E1_Country_New__c, CMPL123CME__D1_Brand_Name__c, CMPL123CME__D4_Catalog_No__c,Submission_Type__c, 
              CMPL123CME__D4_Serial_No__c, CMPL123CME__D4_Lot_No__c, CMPL123CME__D4_Primary_UDI_Number__c, D4_Primary_UDI_Unique_Identifier__c
              FROM EMDR__r ORDER BY CMPL123CME__CMPL123_WF_Status__c)
             
             FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c =: ticketId]) {
                 
                 attachmentIdSet.add(objQuestionnaire.Id);
                 
                 for(CMPL123CME__EMDR__c objEMDR : objQuestionnaire.EMDR__r){
                     if(objEMDR.CMPL123CME__CMPL123_WF_Status__c != '' || objEMDR.CMPL123CME__CMPL123_WF_Status__c != null){
                         if(!emdrStatusMap.containsKey(objEMDR.CMPL123CME__CMPL123_WF_Status__c)){
                             emdrStatusMap.put(objEMDR.CMPL123CME__CMPL123_WF_Status__c, New List<CMPL123CME__EMDR__c>{objEMDR});
                             attachmentIdSet.add(objEMDR.Id);
                         }else{
                             emdrStatusMap.get(objEMDR.CMPL123CME__CMPL123_WF_Status__c).add(objEMDR);
                             attachmentIdSet.add(objEMDR.Id);
                         } 
                     }
                 }
             }
        
        for(CMPL123CME__Questionnaire__c objQuestionnaire : 
            [SELECT Id,
             (SELECT Id,Name,CMPL123CME__Manufacturer_Reference_Number__c,Submitted_Date_new__c,CMPL123CME__HealthcareCountry__c,
              CMPL123CME__Submitter_Name__c, CMPL123CME__Commercial_Name__c,CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c,
              CMPL123CME__Catalogue_Number__c,CMPL123CME__Lot_Numbers__c,Registered_Site_Name__c,CMPL123CME__SubmitterCountry__c,   
              Report_Submitter__c,Waived_Rationale__c,Country__c,Country__r.Name,Submission_Type__c,RecordType.Name,CMPL123CME__Type_of_Report__c FROM MDI__r ORDER BY CMPL123_WF_Status__c)
             
             FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c =: ticketId]) {
                 
                 for(CMPL123CME__MEDDEV__c objMeddev : objQuestionnaire.MDI__r) {
                     if(objMeddev.CMPL123_WF_Status__c != '' || objMeddev.CMPL123_WF_Status__c != null){
                         if(!medDevStatusMap.containsKey(objMeddev.CMPL123_WF_Status__c)){
                             medDevStatusMap.put(objMeddev.CMPL123_WF_Status__c, New List<CMPL123CME__MEDDEV__c>{objMeddev});
                             attachmentIdSet.add(objMeddev.Id);
                         }else{
                             medDevStatusMap.get(objMeddev.CMPL123_WF_Status__c).add(objMeddev);
                             attachmentIdSet.add(objMeddev.Id);
                         } 
                     }
                 }
             }

             for(CMPL123CME__Questionnaire__c objQuestionnaire : 
             [SELECT Id,
              (SELECT Id,Name,CMPL123CME__Manufacturer_S_Reference_Number__c,CMPL123CME__Date_Of_Submission__c,
               CMPL123CME__Registered_Commercial_Name_Of_Company__c,CMPL123CME__Serial_Numbers__c,CMPL123_WF_Status__c,
               CMPL123CME__Catalogue_Reference_Number__c,CMPL123CME__Lot_Batch_Numbers__c,Registerd_Site_Name__c, CMPL123CME__Initial_Reporter_Country__c, 
               Waived_Rationale__c,Country__c,Country__r.Name,Submission_Type__c, Submission_Type__r.Name, CMPL123CME__Type_of_Report__c, CMPL123CME__Submitter_Of_Report__c FROM EU_MIR__r ORDER BY CMPL123_WF_Status__c)
              
              FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c =: ticketId]) {
                  
                  for(CMPL123CME__EU_MIR__c objEumir : objQuestionnaire.EU_MIR__r) {
                      if(objEumir.CMPL123_WF_Status__c != '' || objEumir.CMPL123_WF_Status__c != null){
                          if(!euMirStatusMap.containsKey(objEumir.CMPL123_WF_Status__c)){
                            euMirStatusMap.put(objEumir.CMPL123_WF_Status__c, New List<CMPL123CME__EU_MIR__c>{objEumir});
                              attachmentIdSet.add(objEumir.Id);
                          }else{
                            euMirStatusMap.get(objEumir.CMPL123_WF_Status__c).add(objEumir);
                              attachmentIdSet.add(objEumir.Id);
                          } 
                      }
                  }
              }     
        
        for(CMPL123CME__Questionnaire__c objQuestionnaire : 
            [SELECT Id,
             (SELECT Id FROM CMPL123CME__Questionnaire_Items__r)
             FROM CMPL123CME__Questionnaire__c WHERE CMPL123CME__Complaint__c =: ticketId]) {
                 for(CMPL123CME__Questionnaire_Items__c objQuestionnaireItems : objQuestionnaire.CMPL123CME__Questionnaire_Items__r){
                     attachmentIdSet.add(objQuestionnaireItems.Id);
                 }
             }
        
        for(Attachment__c objAttachment :  
            [SELECT Id, Name, Attachment_Title__c, Attachment_Type__c, Attachment_Description__c, UNC_Path__c,Customer_Response__c,
             Customer_Response_Master__c, EMDR__c, Evaluation_Investigation_Task__c, Investigation_Evaluation__c, MEDDEV__c,EU_MIR__c,
             Assessment__c, Medical_Evaluation_Task__c, Regulatory_Task__c, Return__c, Ticket__c, Tracking_Trending_Review_Task__c 
             FROM Attachment__c 
             WHERE (Customer_Response__c IN :attachmentIdSet OR Customer_Response_Master__c IN :attachmentIdSet OR EMDR__c IN :attachmentIdSet
                    OR Evaluation_Investigation_Task__c IN :attachmentIdSet OR Investigation_Evaluation__c IN :attachmentIdSet
                    OR MEDDEV__c IN :attachmentIdSet OR Assessment__c IN :attachmentIdSet OR Medical_Evaluation_Task__c IN :attachmentIdSet
                    OR Regulatory_Task__c IN :attachmentIdSet OR Return__c IN :attachmentIdSet OR Ticket__c IN :attachmentIdSet
                    OR Tracking_Trending_Review_Task__c IN :attachmentIdSet OR EU_MIR__c IN :attachmentIdSet
                   )]) {
                       
                       String objApiName;
                       if (String.isNotBlank(objAttachment.Customer_Response__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Customer_Response__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Customer_Response_Master__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Customer_Response_Master__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.EMDR__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.EMDR__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Evaluation_Investigation_Task__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Evaluation_Investigation_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Investigation_Evaluation__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Investigation_Evaluation__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.MEDDEV__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.MEDDEV__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.EU_MIR__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.EU_MIR__c.getSObjectType().getDescribe().getName()})[0].getLabel(); 
                       } else if(String.isNotBlank(objAttachment.Assessment__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Assessment__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Medical_Evaluation_Task__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Medical_Evaluation_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Regulatory_Task__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Regulatory_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Return__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Return__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Ticket__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Ticket__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       } else if(String.isNotBlank(objAttachment.Tracking_Trending_Review_Task__c)){
                           objAttachment.UNC_Path__c = Schema.describeSObjects(new List<String>{objAttachment.Tracking_Trending_Review_Task__c.getSObjectType().getDescribe().getName()})[0].getLabel();
                       }
                       
                       attachmentList.add(objAttachment);
                   }
    }
}