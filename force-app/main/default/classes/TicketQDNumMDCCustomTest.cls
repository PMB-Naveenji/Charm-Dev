/* 
* @why  : To Test all scenarios on the class CustomerResponseCustExpectMDCCustom
* @when : CreatedDate : 12-OCT-2018  ModifiedDate : 12-OCT-2018
* @what : CustomerResponseCustExpectMDCCustomTest Test Class
*/

@isTest
public class TicketQDNumMDCCustomTest {
    
    
 /**
* @Method       : setupData
* @Description  : Create Test Data
**/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(Ticket_Type__c = 'Complaint',
                        Complaint_Quality_Closure_Date__c = system.now(),
                        Overall_Reportable_Status__c = 'Reportable',
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Further Review'
                ), true);
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        Name = 'Test',
                        CMPL123_WF_Status__c = 'Assess:In Process-Evaluation:In Process-Investigation:Conclude',
                        Product_Evaluation_Type__c = 'FUF',
                        Additional_Action_Taken__c = 'No',
                        Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                        Conclusion_Summary__c = 'Test',
                        Evaluator_Investigator__c = UserInfo.getUserId(),
                        CMPL123CME__Complaint__c = objComplaint.Id
                ), true);
        TestUtil.setupMDC(
                TicketQDNumMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Quality_Directive_Number__c
        );
    }

    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        TicketQDNumMDCCustom.hasMedEval = true;
        complaint.Quality_Directive_Number__c = 'Num 0001';
        complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);

        TicketQDNumMDCCustom.hasMedEval = null;
        complaint.Quality_Directive_Number__c = 'Num 0002';
        complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);
        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c = :complaint.Id
                AND CMPL123__Action__c = 'Update'
        ][1].CMPL123__Action__c);
        Test.stopTest();
    }
}