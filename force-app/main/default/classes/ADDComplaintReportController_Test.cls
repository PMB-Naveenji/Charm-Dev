/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDComplaintReportController_Test.
* @Why   : ADDComplaintReportController_Test test class for the ADDComplaintReportController class.
* @When  : 30-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                 Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                30-AUG-2018          Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                03-JUN-2020          N/A                           Test class optimization.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                04-JUN-2020          Code Audit                    Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                28-JUL-2020          Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                23-NOV-2020          HC Defect #44                 Update test to match new implementation.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ADDComplaintReportController_Test {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setup() {
        insertData();
    }

    /*
    * @Method       : insertData.
    * @Description  : To insert test data asynchronously.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @future
    public static void insertData () {
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            CMSNext_Ticket_Number__c = '12345'
        ), true);
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(Event_Ticket__c = complaint.Id),
                true
        );
        insert new Contact__c(Ticket__c = complaint.Id, Primary__c = true);
        Ticket_Note__c ticketNote = (Ticket_Note__c) TestDataFactory.createSObject(
                new Ticket_Note__c(Ticket__c = complaint.Id),
                true
        );
        Meaningful_Data__c meaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(
                new Meaningful_Data__c(Compliant__c = complaint.Id),
                true
        );
        Activity__c activity = (Activity__c) TestDataFactory.createSObject(
                new Activity__c(Complaint__c = complaint.Id),
                true
        );
        Customer_Response__c customerResponse = (Customer_Response__c) TestDataFactory.createSObject(
                new Customer_Response__c(Event__c = complaint.Id),
                true
        );
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaint.Id
        ), true);
        pRE_Question__c objPreQuestion = (pRE_Question__c) TestDataFactory.createSObject(
                new pRE_Question__c(
                        pRE_Information__c = preInfo.Id,
                        Answer__c = 'Y'),
                true
        );
        Patient_Information__c patientInformation = (Patient_Information__c) TestDataFactory.createSObject(
                new Patient_Information__c(pRE_Information__c = preInfo.Id),
                true
        );
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id),
                true
        );
        insert new CMPL123CME__Questionnaire_Items__c(CMPL123CME__Questionnaire__c = questionnaire.Id);

        List<Attachment__c> attachments = new List<Attachment__c> {
                new Attachment__c(Assessment__c = questionnaire.Id, Attachment_Type__c = 'Medical Evaluation'),
                new Attachment__c(Customer_Response__c = customerResponse.Id, Attachment_Type__c = 'Medical Evaluation'),
                new Attachment__c(Ticket__c = complaint.Id, Attachment_Type__c = 'Medical Evaluation')

        };

        insert attachments;
    }

    /*
    * @Method       : testComplaintReport.
    * @Description  : To test the ComplaintReport Vf page functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testComplaintReport(){
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        ApexPages.currentPage().getParameters().put('ids','12345');
        ADDComplaintReportController complaintController = new ADDComplaintReportController();
        String keys = complaintController.tickets[0].preQuestionsCategoryMapKeys;
        keys = complaintController.tickets[0].emdrStatusMapKeys;
        keys = complaintController.tickets[0].medDevStatusMapKeys;
        keys = complaintController.tickets[0].productsLotsMapKeys;
        Test.stopTest();

        //Assert the complaint
        //HC Defect #44 fix BEGIN
        System.assertEquals(true, complaintController.tickets[0].ticketsList[0].Id == complaint.Id);
        //HC Defect #44 fix END
    }
}