/* 
* @why  : To Test all scenarios on the class TicketDateofIncidenceProdEvalMDCLogic
* @when : CreatedDate : 20-JUL-2026  ModifiedDate : 20-JUL-2026
* @what : TicketDateofIncidenceProdEvalLogicTest Test Class
*/
@isTest
public class TicketDateofIncidenceProdEvalLogicTest {
    /**
    * @Method       : setupData
    * @Description  : Create Test Data
    **/
    @testSetup 
    public static void setupData() {
        // Create Complaint which is associated with Product Evaluation
        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Service'            
        ), true);
        
        // Create Product Evaluation record
        CMPL123CME__Investigation__c objInvestigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
            new CMPL123CME__Investigation__c(
                CMPL123CME__Complaint__c = complaintTicket.Id,
                Conclusion_Summary__c = 'Conslusion Summarry test1',
                Product_Evaluation_Type__c = 'Lot to lot variability',
                Additional_Action_Taken__c = 'No',
                Close_to_Threshold__c = 'Yes',
                Approval_Date__c = System.today()
            ),  true);   
        
        TestUtil.setupMDC(
            TicketDateofIncidenceProdEvalMDCLogic.class,
            CMPL123CME__Complaint__c.getSObjectType(),
            CMPL123CME__Complaint__c.Date_of_Incidence__c
        );
    }
    
    /**
    * @Method       : customValidationTrueTest
    * @Description  : Verifies that when the Date_of_Incidence__c field is updated
    *                 on a Complaint record associated with a Product Evaluation,
    *                 the TicketDateofIncidenceProdEvalMDCLogic class creates the expected MDC record.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    public static void customValidationTrueTest() {
        Test.startTest();
        CMPL123CME__Complaint__c complaint = [SELECT Id, Date_of_Incidence__c FROM CMPL123CME__Complaint__c LIMIT 1];
       	complaint.Date_of_Incidence__c = DateTime.now();
		complaint = (CMPL123CME__Complaint__c)TestDataFactory.updateSObject(complaint);        
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaint.Id];        
        system.assertEquals(1, mdcCount);
        Test.stopTest();
    }
}