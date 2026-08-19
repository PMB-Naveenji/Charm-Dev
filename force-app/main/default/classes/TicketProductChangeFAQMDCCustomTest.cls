/* 
* @why  : To Test all scenarios on the class TicketProductChangeFAQMDCCustom
* @when : CreatedDate : 24-JUN-2026  ModifiedDate : 24-JUN-2026
* @what : TicketProductChangeFAQMDCCustomTest Test Class
*/
@isTest
public class TicketProductChangeFAQMDCCustomTest {
    
    /**
    * @Method       : setupData
    * @Description  : Create Test Data
    **/    
    @testSetup
    public static void setup(){
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Ticket_Type__c = 'Inquiry',
                Customer_Reply_Required__c = true,
                Complaint_Quality_Closure_Date__c = system.now(),
                Overall_Reportable_Status__c = 'Reportable'
            ), true);
        
        Product_Ticket__c productTicket = (Product_Ticket__c)TestDataFactory.createSObject(
            new Product_Ticket__c(
            	Event_Ticket__c = objComplaint.Id
            ), true);
        
        TestUtil.setupMDC(
            TicketProductChangeFAQMDCCustom.class,
            CMPL123CME__Complaint__c.getSObjectType(),
            CMPL123CME__Complaint__c.Product_Ticket_Added__c
        );
    }
      
    @isTest
    public static void productTicketAddedTest(){
        Ticket_Review__c ticketReview = (Ticket_Review__c) TestDataFactory.createSObject(
            new Ticket_Review__c(
                FA_CAPA_Short_Description__c = 'test',
                CAPA_Number__c = 'test',
                Search_Frequency__c = 'Two Weeks (14 days)',
                Division__c = 'ADD',
                Pending_Batch_Jobs__c = '7070j00000OO6fAAAT',
                Status__c = 'Active',
                Medical_Assignee_Name__c = Userinfo.getUserId()
            ), true);
        CMPL123CME__Complaint__c complaint = [SELECT Id, Ticket_Type__c, Customer_Reply_Required__c FROM CMPL123CME__Complaint__c LIMIT 1];
        TestDataFactory.createSObject(new Ticket_Search_Result__c(
            Ticket_Review__c = ticketReview.Id,
            Ticket_Review_Status__c = 'Related with Malfunction',
            Ticket__c = complaint.Id,
            Unique_Identifier__c = ticketReview.Id + '-' + complaint.Id
        ), true);
        
        Test.startTest();
        complaint.Product_Ticket_Added__c = 'Likely Cause';
        complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :complaint.Id
            AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);
        
        complaint.Product_Ticket_Added__c = 'Likely Cause Likely Cause';
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