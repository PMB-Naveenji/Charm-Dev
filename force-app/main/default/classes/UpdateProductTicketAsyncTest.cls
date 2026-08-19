/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateProductTicketAsyncTest.
* @Why   : To test functionality of UpdateProductTicketAsync class.
* @When  : 04-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  04-JUN-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                   deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class UpdateProductTicketAsyncTest {
    /*
    * @Method       : batchTest.
    * @Description  : To test batch functionality of UpdateProductTicketAsync class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void batchTest() {
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;

        User ssTestUser = TestUtil.insertTestUser(aspenInteg, 'ssTestUser@test.com', 'ssTestUser@test.com');

        System.runAs(ssTestUser) {
            String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
            CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                    new CMPL123CME__Complaint__c(
                            RecordTypeId = complaintRTId,
                            Country_of_origin__c = 'USA'
                    ), true);
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'PATH Vysion',
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = '12345',
                    Reportable_Confirmed_Malfunction_Descrip__c = 'malfunction'
            ), true);

            Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Event_Ticket__c = complaint.Id,
                    Likely_Cause__c = 'Yes',
                    Product__c = product.Id
            ), true);

            Test.startTest();
            Database.executeBatch(new UpdateProductTicketAsync(new Set<Id>{
                    product.Id
            }));
            Test.stopTest();
            Product_Ticket__c productTicketResult = [
                    SELECT Reportable_Confirmed_Malfunction_Descrip__c
                    FROM Product_Ticket__c
                    WHERE Product__c = :product.Id
                    LIMIT 1
            ];
            System.assert(productTicketResult.Reportable_Confirmed_Malfunction_Descrip__c == product.Reportable_Confirmed_Malfunction_Descrip__c);
        }
    }
}