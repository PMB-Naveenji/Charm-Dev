/* 
* @why  : To Test all scenarios on the class CustomerResponseCustExpectMDCCustom
* @when : CreatedDate : 29-OCT-2018  ModifiedDate : 29-OCT-2018
* @what : CustomerResponseCustExpectMDCCustomTest Test Class
*/

@isTest
public class TicketDescAvailableReturnMDCCustomTest {

    /**
   * @Method       : setupData
   * @Description  : Create Test Data
   **/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable',
                        Description_of_Available_Returns__c = 'Test start'
                ), true);

        TestUtil.setupMDC(
                TicketDescAvailableReturnMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Description_of_Available_Returns__c
        );
    }

    @IsTest
    static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Description_of_Available_Returns__c = 'Test';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

        TicketQDNumMDCCustom.hasProdEval = true;
        complaint.Description_of_Available_Returns__c = 'Description';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ][1].CMPL123__Action__c);

        Test.stopTest();
    }
}