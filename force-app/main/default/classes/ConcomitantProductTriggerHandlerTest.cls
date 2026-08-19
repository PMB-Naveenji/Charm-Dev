/* 
* @why  : ConcomitantProductTriggerHandlerTest class for the ConcomitantProductTriggerHandler,
* @when : CreatedDate : 11-DECEMBER-2018         
* @what : Class to Handle Different scenarios from ConcomitantProductTriggerHandlerTest.
* Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*    rslob                   03-June-2020           N/A                  Test class optimization
*  --------------------------------------------------------------------------------------------------------------------------------------
*    vkaih                   6/10/2020              N/A                  Updated code part, which is related to Users' insertion. This 
*                                                                        change designed to prevent a 'DUPLICATE_USERNAME' error during 
*                                                                        deployment to Production environment.
*  --------------------------------------------------------------------------------------------------------------------------------------
* Lakshman              03-Dec-2020         Charm Upgrade        Changed the field value from CMPL123CME__D9_Region_State__c to CMPL123CME__D7b_Region_State__c
* ---------------------------------------------------------------------------------------------------------------------------------------
* Lakshman              03-Dec-2020            Charm Upgrade        Changed the field value from CMPL123CME__D11_Concomitant_Null__c to CMPL123CME__D10_Concomitant_Product_Null__c
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ConcomitantProductTriggerHandlerTest {

    /**
    * @Method       : setup
    * @Description  : Creating records for Ticket object
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup static void setup() {
        insertTestData();
    }

    /**
    * @Method       : insertTestData
    * @Description  : Inserts test setup data asynchronously
    * @Return       : N/A
    * @Params       : N/A
    **/
    @future
    static void insertTestData() {
        //Create User
        User usr = (User) TestDataFactory.createSObject(
            new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
                LastName = 'MainContact',
                Email = 'test@test.com',
                Username = 'test@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'PEI3'),
                true
        );

        // Create Country
        Country__c country = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'USA'), true);

        // Create Country
        Country__c naCountry = (Country__c) TestDataFactory.createSObject(new Country__c(Name = 'NA', Primary_Vigilance_Contact__c = usr.Id), true);

        //Create Account
        Account account = (Account) TestDataFactory.createSObject(new Account(
            Country__c = country.Id,
            ShippingState = 'NA',
            ShippingCountry = 'USA'), true);

        // Create Contact
        Contact contact = (Contact) TestDataFactory.createSObject(new Contact(), true);

        //Create Complaint Code
        CMPL123CME__Complaint_Code__c countryCode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(Name = 'NA', CMPL123CME__Type__c = 'STATE CODE'), true);

        // Create Registered Site
        CMPL123CME__Registered_Site__c rs = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', Division__c = 'ADD'), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        // Create Complaint
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = complaintRTId), true);

        // Create Assessment 
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = assmntRTId,
            CMPL123CME__Complaint__c = complaint.Id), true);

        // Create Investigation 
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
           CMPL123CME__Complaint__c = complaint.Id,
           CMPL123_WF_Status__c = 'Opened',
           CMPL123_WF_Action_Performed_On__c = System.today()), true);
    }

    /**
    * @Method       : createEMDRTestMethod
    * @Description  : Creating EMDR with ConcomitantProduct
    * @Return       : N/A
    * @Params       : N/A
    **/
    static testmethod void createEMDRTestMethod() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [
                SELECT Id, Name
                FROM CMPL123CME__Complaint__c
                WHERE Name != 'cmpltest-00123'
                LIMIT 1
        ];
        Id aspenIntegProfId = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User aspenIntegUser = TestUtil.insertTestUser(aspenIntegProfId, 'aspenIntegUser@test.com', 'aspenIntegUser@test.com');

        System.runAs(aspenIntegUser) {
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345'
            ), true);

            //Create Product ticket
            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Product__c = product.Id,
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = '1235'
            ), true);

            //Get Complaint Code
            CMPL123CME__Complaint_Code__c objComplaintCode = [
                    SELECT ID
                    FROM CMPL123CME__Complaint_Code__c
                    WHERE
                            CMPL123CME__Type__c = 'STATE CODE'
            ];
            //Get Country
            Country__c objCountry = [SELECT Id FROM Country__c Where Name = 'NA' Limit 1];
            CMPL123CME__Questionnaire__c assessment = [
                    SELECT ID
                    FROM CMPL123CME__Questionnaire__c
                    WHERE
                            CMPL123CME__Complaint__c = :complaint.Id
            ];
            //Create Country
            Country__c objectCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

            //Create Country Submission type
            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objectCountry.Id), true);

            //Create EMDR
            CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(CMPL123CME__D7b_Region_State__c = objComplaintCode.Id,
                    D9_Country1__c = objCountry.Id,
                    CMPL123CME__Complaint__c = complaint.Id,
                    CMPL123CME__D3_Region_State__c = objComplaintCode.Id), true);

            //Create Concomitant Product
            CMPL123CME__Concomitant_Product__c objConcomitantProduct = (CMPL123CME__Concomitant_Product__c) TestDataFactory.createSObject(new CMPL123CME__Concomitant_Product__c(
                    CMPL123CME__Related_EMDR__c = emdr.Id,
                    Product_Ticket__c = prodTckt.Id), true);


            System.assertEquals(null, [SELECT ID, CMPL123CME__D10_Concomitant_Product_Null__c FROM CMPL123CME__EMDR__c LIMIT 1].CMPL123CME__D10_Concomitant_Product_Null__c);

            TestDataFactory.deleteSObject(objConcomitantProduct);
        }
        System.assertEquals('NI', [SELECT ID, CMPL123CME__D10_Concomitant_Product_Null__c FROM CMPL123CME__EMDR__c LIMIT 1].CMPL123CME__D10_Concomitant_Product_Null__c);
    }
}