/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS4RegulatorySubmissionsControllerTest.
* @Why   : ADDS4RegulatorySubmissionsControllerTest class for the ADDS4RegulatorySubmissionsController class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak              10-JUN-2020                   N/A                   Updated code part, which is related to Users' insertion.
*                                                                        This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                        deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih              12-AUG-2020             Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Princy             15-JUNE-2021            Code Coverage               Increased the code coverage of test class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Soumith            25-SEP-2024             CHaRM R5                    Created 'mDRFieldsPopulationRS'
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar       16-JAN-2025             CHaRM R6/IPDR 618           Updated the method 'testMDR'
* --------------------------------------------------------------------------------------------------------------------------------------
* Rohit Choudhary     24-FEB-2026             CHaRM R8                  Added new method 'GBMIR_Submission' and Updated 'setup' method to
                                                                        create UK country record. 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
private class ADDS4RegulatorySubmissionsControllerTest {
  
    @TestSetup
    private static void setup() {
           
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId,
                        Country_of_origin__c = 'USA',
                        Division__c = 'ADD'),
                true
        );
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c
                .getRecordTypeInfosByName()
                .get('Initial')
                .getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        RecordTypeId = assmntRTId,
                        CMPL123_WF_Status__c = 'Regulatory',
                        Reportability_Rationale__c = 'Test',
                        Reportability__c = 'Non-Reportable',
                        Reportability_Category__c = 'Adverse Event'),
                true
        );
        
        User user2 = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id,
                LastName = 'test2',
                Email = 'test2@gmail.com',
                Username = 'test2@gmail.com' + System.currentTimeMillis(),
                CompanyName = 'TEST2',
                Title = 'title2',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);
        
        System.runas(user2) 
        {
        //Code Changes for sprint4 start
            CMPL123CME__Registered_Site__c reg = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                    CMPL123CME__Sequence_No__c = '78956',
                    CMPL123CME__Assigned_No__c = '12',
                    
                    Manufacturer_Name__c = 'Abbott',
                    Manufacturer_Phone__c = '12345',
                    Manufacturer_Country__c = 'Germany',                    
                    Authorised_Rep_Contact__c = '34567',
                    Authorised_Rep_Name__c = 'Test123',
                    Authorised_Rep_Phone__c = '54321',
                    Division__c = 'ADD'),
                true
        );
        //Code Changes for sprint4 end

         CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                        CMPL123__Lot_No__c = '123',
                        List_Number__c = '12345',
                        IVDR_Registered_Site__c = reg.id),
                true
        );
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                        Product__c = product.Id,
                        Event_Ticket__c = complaint.Id,
                        Batch_Lot_Serial__c = '1235'),
                true
        );
            TestDataFactory.createSObject(new Ticket_Review__c(Medical_Assignee_Name__c = UserInfo.getUserId(), Status__c = 'Active', Search_Frequency__c = 'Two Weeks (14 days)', Field_Action_Number__c = 'Test', H10_Addtl_Mfg_Narrative__c = 'Test for H11 Additional MFG Narrative', Product__c = product.Id), true);
        }
        
        User user1 = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
                LastName = 'test',
                Email = 'test@gmail.com',
                Username = 'test@gmail.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);
        
        Country__c country = (Country__c) TestDataFactory.createSObject(
                new Country__c(
                        Name = 'USA',//CHaRM-R6
                        Primary_Vigilance_Contact__c = user1.Id,
                        Division__c = 'ADD'),
                true
        );
        Country_Submission_Type__c countrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30-day',//CHaRM R6
                        Calendar_Days__c = 30,
                        Country__c = country.Id),
                true
        );
        //CHaRM R8: setup data for GBMIR submission.
        Country__c country_UK = (Country__c) TestDataFactory.createSObject(
                new Country__c(
                        Name = 'UNITED KINGDOM',
                        Primary_Vigilance_Contact__c = user1.Id,
                        Division__c = 'ADD',
                        Report_Type__c = 'GB MIR'),
                true
        );
        Country_Submission_Type__c countrySubmissionType_UK = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 day',
                        Calendar_Days__c = 30,
                        Country__c = country_UK.Id),
                true
        );
        
    }

    @IsTest
    private static void test() {
       Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        Country__c country = [SELECT Name FROM Country__c LIMIT 1];
        Country_Submission_Type__c countrySubmissionType = [SELECT Name FROM Country_Submission_Type__c LIMIT 1];
        ADDS4RegulatorySubmissionsController controller = new ADDS4RegulatorySubmissionsController(
                new ApexPages.StandardController([
                        SELECT Id
                        FROM CMPL123CME__Questionnaire__c
                        LIMIT 1
                ])
        );

        Test.startTest();
        controller.selectedProductIds = productTicket.Id;
        controller.selectedCountries = country.Name + '-' + countrySubmissionType.Name;
        controller.fetchSelectedSubmissions();
        List<ADDS4RegulatorySubmissionsController.SubmissionDetail> results = controller.submissionDetails;
        controller.createSubmissions();
        controller.submissionDetails.get(0).isSelected = false;
        controller.submissionDetails.get(0).submissionType = 'EUMIR';
        controller.registeredSiteError = false;
        controller.createSubmissions();
        Test.stopTest();

        System.assertNotEquals(null, results);
        
    }
     //Code Changes for sprint4 start
    static testmethod void testMdi(){
        ADDS4RegulatorySubmissionsController controller = new ADDS4RegulatorySubmissionsController(
                new ApexPages.StandardController([
                        SELECT Id
                        FROM CMPL123CME__Questionnaire__c
                        LIMIT 1
                ])
        );
    Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
         Country_Submission_Type__c countrySubmissionType = [SELECT Name FROM Country_Submission_Type__c LIMIT 1];
        CMPL123CME__Registered_Site__c site =[SELECT id FROM CMPL123CME__Registered_Site__c LIMIT 1];
        ADDS4RegulatorySubmissionsController.SubmissionDetail detail = new ADDS4RegulatorySubmissionsController.SubmissionDetail(true, 'UKRAINE', 'MDI(30 Day)', 
                                                                          String.valueOf(countrySubmissionType.id),30, 'IMX FOLATE CTL', '02220-10', '', '', 
                                                                           String.valueOf(productTicket.Id),'', String.valueOf(site.id),'IVDR/MDR',String.valueOf(site.id));
        controller.submissionDetails = new List<ADDS4RegulatorySubmissionsController.SubmissionDetail>{detail};
            test.startTest();
        controller.createSubmissions();
        test.stopTest();
    }
    //To test EMDR
    static testmethod void testMDR(){
            ADDS4RegulatorySubmissionsController controller = new ADDS4RegulatorySubmissionsController(
                new ApexPages.StandardController([
                        SELECT Id
                        FROM CMPL123CME__Questionnaire__c
                        LIMIT 1
                ])
        );
    Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
         Country_Submission_Type__c countrySubmissionType = [SELECT Name FROM Country_Submission_Type__c LIMIT 1];
        CMPL123CME__Registered_Site__c site =[SELECT id FROM CMPL123CME__Registered_Site__c LIMIT 1];
        ADDS4RegulatorySubmissionsController.SubmissionDetail detail = new ADDS4RegulatorySubmissionsController.SubmissionDetail(true, 'USA', 'eMDR(30-day)', //CHaRM R6
                                                                          String.valueOf(countrySubmissionType.id),30, 'IMX FOLATE CTL', '02220-10', '', '', 
                                                                           String.valueOf(productTicket.Id),'', String.valueOf(site.id),'IVDR/MDR',String.valueOf(site.id));
        controller.submissionDetails = new List<ADDS4RegulatorySubmissionsController.SubmissionDetail>{detail};

        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];//Charm R6
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];//Charm R6
            test.startTest();
        controller.createSubmissions();
        test.stopTest();
       // CHaRM R6 - Start- To check the G6- Type of Report field is getting populated from the country submission-Type and the record Type of the emdr.
         Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();       
        CMPL123CME__EMDR__c emdrRec = new CMPL123CME__EMDR__c();
             emdrRec.RecordTypeId =initialRTId;
             emdrRec.CMPL123CME__EMDR_Form_Version__c =  '2023';
             emdrRec.Division__c =  'ADD';
             emdrRec.Medical_Evaluation__c = questionnaire.Id;
             emdrRec.CMPL123CME__Registered_Site__c = site.id;
             emdrRec.Product__c = productTicket.Id;
             emdrRec.CMPL123CME__Complaint__c = complaint.Id;
             emdrRec.Submission_Type__c = countrySubmissionType.Id;
          Insert  emdrRec; 
        emdrRec.CMPL123CME__G3_Date_received_by_Mfg__c = System.today();
        Update emdrRec;
        CMPL123CME__EMDR__c emdrRec1 = [Select CMPL123CME__G6_Type_of_Report__c From CMPL123CME__EMDR__c WHERE id =: emdrRec.id];
        System.assertEquals('30-day;Initial', emdrRec1.CMPL123CME__G6_Type_of_Report__c );
        //CHaRM R6 - End
        
    }
     //Code Changes for sprint4 end
     
    //CHaRM R5: Start
    /*
    * @Method       : mDRFieldsPopulationRS
    * @Description  : Check the asserts for MDI. Wheather 'Manufacturer information' & 'Authorised representative information' fields are getting populated from Registerd site.
    * @Return       : N/A
    * @Params       : N/A
    */
     Public static testmethod void mDRFieldsPopulationRS(){
         ADDS4RegulatorySubmissionsController controller = new ADDS4RegulatorySubmissionsController(
                new ApexPages.StandardController([
                        SELECT Id
                        FROM CMPL123CME__Questionnaire__c
                        LIMIT 1
                ])
        );
         
        CMPL123CME__Registered_Site__c site =[SELECT id FROM CMPL123CME__Registered_Site__c LIMIT 1];
        CMPL123__Product__c prod = [Select id, Registered_Site__c,IVDR_Registered_Site__c from CMPL123__Product__c 
                                 WHERE CMPL123__Product__c.IVDR_Registered_Site__c =: site.id];
        Product_Ticket__c productTicket = [SELECT Id,Product__c FROM Product_Ticket__c WHERE Product_Ticket__c.Product__c =: prod.id];
     
        Country_Submission_Type__c countrySubmissionType = [SELECT Name FROM Country_Submission_Type__c LIMIT 1];
        ADDS4RegulatorySubmissionsController.SubmissionDetail detail = new ADDS4RegulatorySubmissionsController.SubmissionDetail(true, 'USA', 'MDR(30-day)', //CHaRM R6
                                                                          String.valueOf(countrySubmissionType.id),30, 'IMX FOLATE CTL', '02220-10', '', '', 
                                                                           String.valueOf(productTicket.Id),'', String.valueOf(site.id),'IVDR/MDR',String.valueOf(site.id));
        controller.submissionDetails = new List<ADDS4RegulatorySubmissionsController.SubmissionDetail>{detail};
            
        CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
            
        test.startTest();
        controller.createSubmissions();
          CMPL123CME__MEDDEV__c mdiRec = new CMPL123CME__MEDDEV__c();
             mdiRec.Medical_Evaluation__c = questionnaire.Id;
             mdiRec.Country__c = country.Id;
             mdiRec.Registered_Site__c = site.id;
             mdiRec.Product__c = productTicket.Id;
             mdiRec.CMPL123CME__Complaint__c = complaint.Id;
          Insert  mdiRec; 
         
         CMPL123CME__MEDDEV__c newMed = [Select CMPL123CME__Manufacturer_Name__c,CMPL123CME__Manufacturer_Phone__c,CMPL123CME__ManufacturerCountry__c,
                                         CMPL123CME__Authorised_Representative_Contact__c,CMPL123CME__Authorised_Representative_Name__c,CMPL123CME__Authorised_Representative_Phone__c
                                          from CMPL123CME__MEDDEV__c WHERE id =: mdiRec.id];
      
          System.assertEquals('Abbott', newMed.CMPL123CME__Manufacturer_Name__c );
          System.assertEquals('12345', newMed.CMPL123CME__Manufacturer_Phone__c );
          System.assertEquals('Germany', newMed.CMPL123CME__ManufacturerCountry__c );
          System.assertEquals('34567', newMed.CMPL123CME__Authorised_Representative_Contact__c );
          System.assertEquals('Test123', newMed.CMPL123CME__Authorised_Representative_Name__c );
          System.assertEquals('54321', newMed.CMPL123CME__Authorised_Representative_Phone__c );
        test.stopTest();
           
    }
    //CHaRM R5: End
    /*
    * @Method       : GBMIR_Submission
    * @Description  : ChaRM R8: Added new method to test the GB MIR submissions
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    private static void GBMIR_Submission() {
       Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        Country__c country = [SELECT Id, Name FROM Country__c WHERE Name='UNITED KINGDOM'];
        Country_Submission_Type__c countrySubmissionType = [SELECT Name FROM Country_Submission_Type__c Where Country__c=:country.Id];
        ADDS4RegulatorySubmissionsController controller = new ADDS4RegulatorySubmissionsController(
                new ApexPages.StandardController([
                        SELECT Id
                        FROM CMPL123CME__Questionnaire__c
                        LIMIT 1
                ])
        );

        Test.startTest();
        controller.selectedProductIds = productTicket.Id;
        controller.selectedCountries = country.Name + '-' + countrySubmissionType.Name;
        controller.fetchSelectedSubmissions();
        List<ADDS4RegulatorySubmissionsController.SubmissionDetail> results = controller.submissionDetails;
        controller.createSubmissions();
        Test.stopTest();
        System.assertNotEquals(null, results);
    }  
}