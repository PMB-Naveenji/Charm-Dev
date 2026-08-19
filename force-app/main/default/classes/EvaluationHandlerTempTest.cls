/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : EvaluationHandlerTempTest.
* @Why   : EvaluationHandlerTempTest test class for the EvaluationHandlerTemp class.
* @When  : 24-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 24-AUG-2018         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 17-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class EvaluationHandlerTempTest{

    /*
    * @Method       : afterUpdateEventHandler.
    * @Description  : To test the EvaluationHandlerTemp class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static testMethod void afterUpdateEventHandler(){
        // Test Data
        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = new CMPL123CME__Complaint__c(RecordTypeId = complaintRecTypeId);
        insert complaint;
        Customer_Response__c customerRes = new Customer_Response__c(Event__c = complaint.id,Customer_Reply__c = 'Test Customer reply');
        insert customerRes;
        Customer_Response__c customerRec = new Customer_Response__c(Event__c = complaint.id,Customer_Reply__c = 'Test Customer reply');
        insert customerRec ;
        KI_Log__c KILogRec = new KI_Log__c(Customer_Reply__c = 'Test', Type__c = 'Product Evaluation');
        insert KILogRec;
        CMPL123CME__Investigation__c investigationRec = new CMPL123CME__Investigation__c(CMPL123CME__Complaint__c = complaint.id,KI_Log__c = KILogRec.id);
        insert investigationRec;
        // Check auto update
        Customer_Response__c  fieldCheckNull = [SELECT Id,Customer_Reply__c FROM Customer_Response__c  WHERE Id=:customerRec.id];
        system.assertEquals('Test Customer reply',fieldCheckNull.Customer_Reply__c );
        Customer_Response__c  fieldCheck = [SELECT Id,Customer_Reply__c FROM Customer_Response__c  WHERE Id=:customerRes.id];
        system.assertEquals('Test Customer reply',fieldCheck.Customer_Reply__c );
    }

}