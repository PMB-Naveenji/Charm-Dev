/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ReportsRelatedDataUtilTest.
* @Why   : ReportsRelatedDataUtilTest test class for the ReportsRelatedDataUtil class.
* @When  : 05-JUL-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Odemi                 05-JUL-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 21-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ReportsRelatedDataUtilTest {
    
    /*
    * @Method       : setup.
    * @Description  : To create data for tests.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        ADD_App_Settings__c appSetting = new ADD_App_Settings__c();
        appSetting.Restrict_Workflow_Updates__c = true;
        appSetting.Name = 'User';
        appSetting.Restrict_Triggers__c = true;
        appSetting.Restrict_Validation_Rules__c = true;
        insert appSetting;
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'INDIA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMSNext_Ticket_Number__c = '12345'),
                true
        );
        insert new CMPL123CME__Investigation__c(
                Name = 'Test',
                CMPL123_WF_Status__c = 'Open',
                CAPA_Reference__c = 'Test',
                Is_Investigation_Required__c = 'Test',
                Product_Evaluation_Type__c = 'FUF',
                Additional_Action_Taken__c = 'No',
                Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                Conclusion_Summary__c = 'Test',
                CMPL123CME__Complaint__c = complaint.Id);
        Post_Market_Risk_Assessment_Risk_Contr__c postMarketRiskAssessmentRiskContr = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
                new Post_Market_Risk_Assessment_Risk_Contr__c(Division__c = 'ADD'),
                true
        );
        CMPL123CME__Registered_Site__c registeredSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                        CMPL123CME__Site_Name__c = 'Test',
                        Division__c = 'ADD'),
                true
        );
        CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                        Name = 'Test',
                        CMPL123__Lot_No__c = '123',
                        List_Number__c = 'Test',
                        Registered_Site__c = registeredSite.Id,
                        Post_Market_Risk_Asst_Risk_Ctrl__c = postMarketRiskAssessmentRiskContr.Id),
                true
        );
        insert new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Product__c = product.Id
        );
        insert new Risk_Assessment__c(
                Post_Market_Risk_Asst_Risk_Ctrl__c = postMarketRiskAssessmentRiskContr.Id,
                Product__c = product.Id
        );
        insert new Ticket_Note__c(
                Ticket__c = complaint.Id,
                Ticket_Notes_Native__c = 'Test'
        );
    }
    
    /*
    * @Method       : testInvestigationUpdateComplaint.
    * @Description  : To test Investigation update Complaint.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testInvestigationUpdateComplaint() {

        List<CMPL123CME__Investigation__c> investigations = [
                SELECT CAPA_Reference__c, Is_Investigation_Required__c, CMPL123CME__Complaint__c
                FROM CMPL123CME__Investigation__c
        ];

        Test.startTest();
        ReportsRelatedDataUtil.updateComplaintWithInvestigationsData(investigations, null);
        Test.stopTest();

        CMPL123CME__Complaint__c complaint = [
                SELECT CAPA_Reference__c, Is_Investigation_Required__c
                FROM CMPL123CME__Complaint__c
                WHERE CMSNext_Ticket_Number__c = '12345'
                LIMIT 1
        ];
        System.assert(complaint.CAPA_Reference__c.contains('Test'));
        System.assert(complaint.Is_Investigation_Required__c.contains('Test'));
    }

    /*
    * @Method       : testPMRAUpdate.
    * @Description  : To test PMRA update.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    private static void testPMRAUpdate() {
        List<Risk_Assessment__c> riskAssessment = [
                SELECT Post_Market_Risk_Asst_Risk_Ctrl__c, Product_Name__c, Product_List_Number__c
                FROM Risk_Assessment__c
        ];

        Test.startTest();
        ReportsRelatedDataUtil.updatePMRAWithRiskAssessmentsData(null, riskAssessment);
        Test.stopTest();

        Post_Market_Risk_Assessment_Risk_Contr__c pmra = [
                SELECT Related_Product_List_Product_Name__c, Product_List_Number__c
                FROM Post_Market_Risk_Assessment_Risk_Contr__c
                LIMIT 1
        ];

        System.assert(pmra.Related_Product_List_Product_Name__c.contains('Test'));
        System.assert(pmra.Product_List_Number__c.contains('Test'));
    }

    @IsTest
    private static void testProductTicketUpdateComplaint() {
        List<Product_Ticket__c> oldProductTickets = [
                SELECT Event_Ticket__c, Registered_Site_Name__c
                FROM Product_Ticket__c
        ];
        List<Product_Ticket__c> newProductTickets = [
                SELECT Event_Ticket__c, Product__r.Registered_Site__r.CMPL123CME__Site_Name__c, Registered_Site_Name__c
                FROM Product_Ticket__c
        ];
        newProductTickets.get(0).Product__r.Registered_Site__r.CMPL123CME__Site_Name__c = 'new test';
        CMPL123CME__Complaint__c oldComplaint = [
                SELECT Manufacturing_Site__c
                FROM CMPL123CME__Complaint__c
                WHERE CMSNext_Ticket_Number__c = '12345'
                LIMIT 1
        ];

        Test.startTest();
        ReportsRelatedDataUtil.updateComplaintWithRegisteredSiteNames(oldProductTickets, newProductTickets);
        Test.stopTest();

        CMPL123CME__Complaint__c newComplaint = [
                SELECT Manufacturing_Site__c
                FROM CMPL123CME__Complaint__c
                WHERE CMSNext_Ticket_Number__c = '12345'
                LIMIT 1
        ];
        System.assert(oldComplaint.Manufacturing_Site__c == newComplaint.Manufacturing_Site__c);
    }

    /*
    * @Method       : testTicketNotesUpdateComplaint.
    * @Description  : To test Ticket Notes update Complaint.
    * @Invoke       : N/A.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    private static void testTicketNotesUpdateComplaint() {
        List<Ticket_Note__c> ticketNotes = [
                SELECT Ticket_Notes_Native__c, Ticket_Notes_Translated__c, Ticket__c
                FROM Ticket_Note__c
        ];

        Test.startTest();
        ReportsRelatedDataUtil.updateComplaintWithTicketNotesData(null, ticketNotes);
        Test.stopTest();

        CMPL123CME__Complaint__c newComplaint = [
                SELECT Ticket_Notes_Native__c
                FROM CMPL123CME__Complaint__c
                WHERE CMSNext_Ticket_Number__c = '12345'
                LIMIT 1
        ];
        System.assert(newComplaint.Ticket_Notes_Native__c.contains('Test'));
    }
}