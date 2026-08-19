/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ComplaintTicketReportTest.
* @Why   : ComplaintTicketReportTest test class for the ComplaintTicketReport class.
* @When  : 14 Dec 2020
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Aslam                14 Dec 2020
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class ComplaintTicketReportTest {    
    /*
* @Method       : setup.
* @Description  : To insert test data.
* @Invoke       : N/A.
* @Return       : N/A.
* @Params       : N/A.
*/
    
    @TestSetup
    private static void setup() {
        insertTestData();
    }
    
    /*
* @Method       : insertTestData.
* @Description  : Helper to insert test data with increased limits.
* @Invoke       : N/A.
* @Return       : N/A.
* @Params       : N/A.
*/
    @future
    static void insertTestData() {
        
        // Create Complaint Customer
        Account  objAccount = (Account ) TestDataFactory.createSObject(new Account (
            Name = 'Test Account',
            Contact_Address_Line_1__c = 'Test Contact1',
            Contact_Address_Line_2__c = 'Test Contact2',
            City__c = 'Test City',
            State__c = 'Test State'),true);
        
        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c = 'ADD',
            pRE_Status__c = 'Yes',
            Country_of_origin__c = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c = 'IA-CC',
            CMPL123CME__Customer__c = objAccount.id,
            Ticket_Type__c = 'Complaint',
            Is_Product_Evaluation_Investigation_chil__c = false,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            CMSNext_Ticket_Number__c = '123456'
        ), true);
        
        insert new Contact__c(Ticket__c = complaint.Id, Primary__c = true);
        //Create Product Ticket
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
            new Product_Ticket__c(Event_Ticket__c = complaint.Id),true);
        
        //Create Tickets Notes
        Ticket_Note__c ticketNote = (Ticket_Note__c) TestDataFactory.createSObject(
            new Ticket_Note__c(Ticket__c = complaint.Id),
            true);
        insert new Meaningful_Data__c(Compliant__c = complaint.Id);
        
        //Create Customer Response
        Customer_Response__c customerRes = (Customer_Response__c) TestDataFactory.createSObject(new Customer_Response__c(
            Event__c  = complaint.Id,
            CMPL123_WF_Status__c = 'Opened'),true);
        
        //Create Activities
        Activity__c sObj = (Activity__c)TestDataFactory.createSObject(
            new Activity__c(
                Activity_Type__c = 'test',
                complaint__c =complaint.id
            ),
            true);
        //Create pre Information
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(
            new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaint.Id),
            true
        );
        
        insert new pRE_Question__c(
            pRE_Information__c = preInfo.Id,
            Answer__c = 'Y'
        );
        
        //Create Country
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        
        //Create Country Submission
        Country_Submission_Type__c  objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30 Days',
            Calendar_Days__c = 30,
            Country__c = objCountry.Id
        ), true);
        
        //Create Questionnaire
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id),
            true
        );
        
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        CMPL123_WF_Status__c = 'Regulatory',
                        Reportability_Rationale__c = 'Test',
                        Reportability__c = 'Non-Reportable',
                        Reportability_Category__c = 'Adverse Event',
                        Initial_Awareness_Date__c = Date.newInstance(2018, 05, 07),
                        Submitted_Date__c = Date.newInstance(2018, 05, 07)

                ), true);
        
        //create EUMIR record
        CMPL123CME__EU_MIR__c eumirRecord = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                        MedicalEvaluation__c = assessment.Id,
                        Country__c = Objcountry.Id,
                        Product__c = productTicket.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened',
                        CMPL123CME__MDR_Class__c = 'class III',
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        CMPL123CME__Preliminary_Results_And_Conclusions__c = 'test' 
            ),true);
        
        //@Lakshman
        ComplaintTicketReportResult ctrr = new ComplaintTicketReportResult();
        
        String question = ctrr.preQuestionsCategoryMapKeys;
		Integer questionMap = ctrr.preQuestionsCategoryMapSize;

        String emdr = ctrr.emdrStatusMapKeys;
		Integer emdrMap = ctrr.emdrStatusMapSize;

        String medDev = ctrr.medDevStatusMapKeys;
		Integer medDevMap = ctrr.medDevStatusMapSize;

        String euMir = ctrr.euMirStatusMapKeys;
		Integer euMirMap = ctrr.euMirStatusMapSize;

        String productLot = ctrr.productsLotsMapKeys;

        //Create EMDR Record
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdRecord =  (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
            new CMPL123CME__EMDR__c(
                RecordTypeId = EMDRInitial,
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                //CHaRM-R4: Added CMPL123CME__D4_Primary_UDI_Number__c
                CMPL123CME__D4_Primary_UDI_Number__c = 'Testing UDI',
                Medical_Evaluation__c = questionnaire.Id  
            ),true);
        
        insert new Patient_Information__c(pRE_Information__c = preInfo.Id);
        
        
        Customer_Response_Master__c crm = (Customer_Response_Master__c) TestDataFactory.createSObject(
            new Customer_Response_Master__c(
                CMPL123Rule_Key_Value__c = 'CUSTOMER_RESPONSE_MASTER_WORKFLOW',
                CMPL123_WF_Action__c = 'Retire',
                CMPL123_WF_Status__c = 'Closed-Retired',
                Category__c = 'Storage',
                Customer_Letter_Approval_Date__c = Date.valueOf('2019-01-14'),
                Keyword_List__c = 'Plasma',
                List_Number__c = '2K91',
                Reference_Documentation__c = 'List of Reference Documents',
                Source_Registration_Ticket_Number__c = '117117RA1064525',
                Source_Ticket_Type__c = 'Inquiry',
                Retired_By__c = 'add business_admin',
                Customer_Letter_Approved_By__c = 'add business_admin',
                Customer_Reponse_Master_Title__c = 'test1',
                Division__c = 'ADD',
                Category_Text_Hidden__c = 'Storage'
            ), true
        );
        
        
        Profile aspenIntegrationProfile = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'];
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];
        
        User aspenInteg = TestUtil.insertTestUser(
            aspenIntegrationProfile.Id,
            'test@test.com',
            'aspenIntegrationTest@test.com'
        );
        
        User aspenUser = TestUtil.insertTestUser(
            aspenUserProfile.Id,
            'test2@test.com',
            'aspenUserTest@test.com'
        );
        
        System.runAs(aspenInteg) {
            TestDataFactory.createSObject(new CMPL123__Product__c(Name = 'Test'), true);
        }
        
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
            new CMPL123CME__Investigation__c(
                Name = 'Test',
                CMPL123_WF_Status__c = 'Assess:In Process-Evaluation:In Process-Investigation:Conclude',
                Product_Evaluation_Type__c = 'FUF',
                Additional_Action_Taken__c = 'No',
                Approver__c = aspenUser.Id,
                Assessor__c = aspenUser.Id,
                Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                Conclusion_Summary__c = 'Test',
                Evaluator_Investigator__c = aspenInteg.Id,
                CMPL123CME__Complaint__c = complaint.Id),
            true
        );
        
        Task__c task = (Task__c) TestDataFactory.createSObject(
            new Task__c(
                Related_Investigation_Evaluation__c = investigation.Id,
                CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                Source_Leveraged__c = 'Leveraged',
                CMPL123_WF_Status__c = 'Opened:In Process'),
            true
        );
        
        List<Attachment__c> attachments = new List<Attachment__c>();
        attachments.add(new Attachment__c(Customer_Response__c = customerRes.Id, EMDR__c = emdRecord.Id,  Customer_Response_Master__c = crm.Id, Attachment_Type__c = 'Medical Evaluation'));
        attachments.add(new Attachment__c( EMDR__c = emdRecord.Id, Customer_Response_Master__c = crm.Id, Attachment_Type__c = 'Medical Evaluation'));
        attachments.add(new Attachment__c( EMDR__c = emdRecord.Id, Attachment_Type__c = 'Medical Evaluation'));
        attachments.add(new Attachment__c(Evaluation_Investigation_Task__c = task.Id, Attachment_Type__c = 'Medical Evaluation'));
        attachments.add(new Attachment__c( Investigation_Evaluation__c = investigation.Id, Attachment_Type__c = 'Medical Evaluation' ));
        
        insert attachments;

        
    }
    
    /*
* @Method       : test.
* @Description  : To test the ComplaintTicketReportController functionality.
* @Invoke       : N/A.
* @Return       : N/A.
* @Params       : N/A.
*/
    @IsTest
    private static void test() {
        Test.startTest();
        List<String> myList = new List<String>();
        Integer size = ComplaintTicketReport.Generate(new List<String>{'123456'}).size();
        system.assertEquals(1, size);
        
		
        Test.stopTest();
    }
    
}