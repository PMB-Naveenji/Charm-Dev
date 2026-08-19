/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : PTWithMedEvalListNumberMDCCustomTest.
* @Why   : PTWithMedEvalListNumberMDCCustomTest test class for the PTWithMedEvalListNumberMDCCustom class.
* @When  : 31-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    31-JUL-2020            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class PTWithMedEvalListNumberMDCCustomTest {
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {

        TestUtil.setupMDC(
            PTWithMedEvalListNumberMDCCustom.class,
            Product_Ticket__c.getSObjectType(),
            Product_Ticket__c.Product_List_Number_Text__c
        );

        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = compRecTypeId,
                Ticket_Type__c = 'Complaint'),
            true
        );

        Id aspenIntegProfId = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User aspenIntegUser = TestUtil.insertTestUser(aspenIntegProfId, 'aspenIntegUser@test.com', 'aspenIntegUser@test.com');

        System.runAs(aspenIntegUser){

            CMPL123__Product__c objProduct = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    List_Number__c = 'Test'
                ), true
            );

            CMPL123__Product__c objProductUpdate = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    List_Number__c = 'Test Update'
                ), true
            );

            Product_Ticket__c objPT = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Event_Ticket__c = objComplaint.Id,
                    Likely_Cause__c = 'Yes',
                    Batch_Lot_Serial__c = '123 Lot Serial Number',
                    Product__c = objProduct.id),
                true
            );
        }
    }

    /*
    * @Method       : customValidationTest.
    * @Description  : To test the PTWithMedEvalListNumberMDCCustom functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void customValidationTest() {

        Product_Ticket__c recordPT = [SELECT Id, Product_List_Number_Text__c, Event_Ticket__c FROM Product_Ticket__c];
        CMPL123__Product__c recordProduct = [SELECT Id, List_Number__c FROM CMPL123__Product__c WHERE List_Number__c = 'Test Update'];

        Test.startTest();

        recordPT.Product__c = recordProduct.id;
        TestDataFactory.updateSObject(recordPT);

        Test.stopTest();

        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: recordPT.Id AND CMPL123__Action__c = 'Insert']) {
             System.assertEquals('Insert', entry.CMPL123__Action__c);
        }
        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: recordPT.Id AND CMPL123__Action__c = 'Update']) {
             System.assertEquals('Update', entry.CMPL123__Action__c);
        }

    }
}