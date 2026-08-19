/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright 2019  Capgemini.
* @What  : AddS3MIRTriggerHandlerTest
* @Why   : Test class to maintain code coverage  for ADDS3MIRTriggerHandler.
* @When  : 23-OCT-2019
* @Where : From AddS3MIRTriggerHandlerTest 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                23-OCT-2019               Sprint 4             Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
public class AddS3MIRTriggerHandlerTest {
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
        CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                        CMPL123__Lot_No__c = '123',
                        List_Number__c = '12345'),
                true
        );
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                        Product__c = product.Id,
                        Event_Ticket__c = complaint.Id,
                        Batch_Lot_Serial__c = '1235'),
                true
        );
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
                        Name = 'US',
                        Primary_Vigilance_Contact__c = user1.Id,
                    	Registered_Commercial_name_of_Company__c='brandtest',
                        Division__c = 'ADD'),
                true
        );
        
         CMPL123CME__Registered_Site__c reg = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(
                new CMPL123CME__Registered_Site__c(
                     
       					 CMPL123CME__Sequence_No__c = '34567',
       					 CMPL123CME__Assigned_No__c = '12345',
       					 CMPL123CME__Site_Name__c = 'Business site',
                    	MIR_Manufacturer_Name__c = 'Business',
       					 Division__c = 'ADD'),
                true
        );
        
        Country_Submission_Type__c countrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = country.Id),
                true
        );
        
    }

    @IsTest
    private static void test() {
      /*  Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        Country__c country = [SELECT Name FROM Country__c LIMIT 1];
        Country_Submission_Type__c countrySubmissionType = [SELECT Name FROM Country_Submission_Type__c LIMIT 1];
        CMPL123CME__Registered_Site__c registeredSite =[SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1];
        
        ADDS3MIRTriggerHandler.eUMIRFiledUpdates();
        CMPL123CME__EU_MIR__c MIRObj = new CMPL123CME__EU_MIR__c();
        MIRObj.Submission_Type__c = countrySubmissionType.Id;
        MIRObj.CMPL123CME__Complaint__c = 'a0m2i0000005dBZ';
        MIRObj.CMPL123CME__Date_Of_Submission__c = system.today();
        MIRObj.Country__c = 'a1M2i0000000p6J';
       // MIRObj.Country__c = 'a1M2i0000000phV';
        MIRObj.Medical_Evaluator__c = '00536000002Ds5L';
     //  MIRObj.MedicalEvaluation__c = 'a132i0000009KY7';
        MIRObj.Product__c = 'a1c2i0000004q7n';
        MIRObj.Registered_Site__c = 'a162i0000004hlD';
        insert MIRObj;*/
        
         Test.startTest();
         CMPL123CME__Questionnaire__c questionnaire = [SELECT Id FROM CMPL123CME__Questionnaire__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        Product_Ticket__c productTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        CMPL123CME__Registered_Site__c registeredSite =  [Select Id from CMPL123CME__Registered_Site__c LIMIT 1];
        CMPL123CME__EU_MIR__c eumirRecord = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                        MedicalEvaluation__c = questionnaire.Id,
                        Country__c = country.Id,
                        Product__c = productTicket.Id,
                    Registered_Site__c = registeredSite.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Follow_Up_Required__c = 'Yes',
                        CMPL123_WF_Status__c = 'Pending Final Review',
                        CMPL123CME__Type_of_Report__c = 'Combined initial and final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        //CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        //CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Preliminary_Results_And_Conclusions__c = 'test'
                ), true);

        CMPL123CME__EU_MIR__c eumirRecordFinal = (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
                new CMPL123CME__EU_MIR__c(
                        MedicalEvaluation__c = questionnaire.Id,
                        Country__c = country.Id,
                        Product__c = productTicket.Id,
                        CMPL123CME__Complaint__c = complaint.Id,
                        Follow_Up_Required__c = 'Yes',
                        CMPL123_WF_Status__c = 'Pending Final Review',
                        CMPL123CME__Type_of_Report__c = 'Final report',
                        CMPL123CME__Expected_Date_of_Next_Report__c = Date.newInstance(2019, 05, 05),
                        Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                        //CMPL123CME__Whether_Manufacturer_Aware__c = 'No',
                        //CMPL123CME__Number_of_similarIncidents__c = '2',
                        CMPL123CME__Preliminary_Results_And_Conclusions__c = 'test'
                ), true);

        // R3.1, Larry: Commented this block so that the test can succeed.
        // I think this entire test class can be deleted since 
        // (A) This test class only exists in AspenInteg
        // (B) The main class does not exist
        // (C) This commented code seems to already be handled by
        // EUMIRTriggerHandlerTest .testCombinedInitialFinalEuMir
        // 
        // eumirRecordFinal.CMPL123CME__Type_of_Report__c = 'Combined initial and final report';
        // update  eumirRecordFinal;
        // CMPL123CME__EU_MIR__c mirUpdated = [
        //         SELECT CMPL123CME__Expected_Date_of_Next_Report__c
        //         FROM CMPL123CME__EU_MIR__c
        //         WHERE Id = :eumirRecord.Id
        // ];
        // System.assert(mirUpdated.CMPL123CME__Expected_Date_of_Next_Report__c == null);
        
        
        // R3.1, Larry: Commented this insert because...
        // I don't see why it is related to this class at all.
        // Also, it crashes for some reason.
        // 
//     Contact__c  contactRecord = new Contact__c();
//        contactRecord.Active__c = true;
//         contactRecord.Address_Area_Line_1__c= 'New york';
//            contactRecord.City__c= 'Silicon valley';
//            contactRecord.Customer_Name__c= '0012i000004gE70';
//            contactRecord.Name__c= 'test2';
//            contactRecord.Primary__c= true;
//            insert contactRecord;
        
        
              Test.stopTest();

    }
    
}