/* 
* @why  : To Test all scenarios on the class ticketDateofIncidenceMDCLogic
* @when : CreatedDate : 26-SEP-2024  ModifiedDate : 
* @what : ticketDateofIncidenceMDCLogicTest Test Class
*/
@isTest
private class ticketDateofIncidenceMDCLogicTest {
    
    /**
* @Method       : setupData
* @Description  : Create Test Data
**/  
    @testSetup static void setupData() {
        //Create CMPL123CME__Complaint__c
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(), true);
        TestUtil.setupMDC(
                ticketDateofIncidenceMDCLogic.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Date_of_Incidence__c
        );
    }
    
    /**
* @Method       : CustomValidation
* @Description  : Test method to cover CustomValidation method in ticketDateofIncidenceMDCLogic Class
**/
    @isTest
    static void CustomValidation() {
        Test.startTest();
        CMPL123CME__Complaint__c objComplaint = [SELECT Id, Date_of_Incidence__c FROM CMPL123CME__Complaint__c LIMIT 1];
        objComplaint.Date_of_Incidence__c = DateTime.now();
        objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.updateSObject(objComplaint);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :objComplaint.Id
                AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
        Test.stopTest();
    }
}