/* 
* @why  : TicketSearchTriggerHandlerTest class for the ADDMeaningfulDataTriggerHandler,
* @when : CreatedDate : 06-JAN-2021         
* @what : Class to Handle Different scenarios from ADDMeaningfulDataTriggerHandler.
*  Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID         Description 
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                06-JAN-2021            TWD Upgrade Issue       Created. Added method testWFlogic 
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TicketSearchTriggerHandlerTest {

    /*
    * @Method       : init
    * @Description  : setup data
    * @Return       : N/A
    * @Params       : N/A
    */ 
    @testSetup static void init(){
        Profile aspenUserProfile = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User aspenUser = TestUtil.insertTestUser(
                aspenUserProfile.Id,
                'test22@test.com',
                'aspenUser2Test@test.com'
        );
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '12345',
                Ticket_Description__c = 'Ticket_Description__c'),
                true
        );
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        Name = 'Test',
                        CMPL123_WF_Status__c = 'Assess:In Process-Evaluation:In Process-Investigation:Conclude',
                        Product_Evaluation_Type__c = 'FUF',
                        Additional_Action_Taken__c = 'No',
                        Approver__c = aspenUser.Id,
                        Assessor__c = UserInfo.getUserId(),
                        Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                        Conclusion_Summary__c = 'Test',
                        Evaluator_Investigator__c = UserInfo.getUserId(),
                        CMPL123CME__Complaint__c = complaint.Id),
                true
        );

        Task__c task = (Task__c) TestDataFactory.createSObject(
                new Task__c(
                        Related_Investigation_Evaluation__c = investigation.Id,
                        CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                        Source_Leveraged__c = 'Leveraged',
                        CMPL123_WF_Status__c = 'Opened'),
                true
        );
    }
    
    /*
    * @Method       : testWFlogic
    * @Description  : Test logic from disabled WF rule:  Update Ticket Description 
    * @Return       : N/A
    * @Params       : N/A
    */ 
    @isTest static void testWFlogic(){
        Task__c task = [SELECT Id FROM Task__c LIMIT 1];
        Ticket_Serach__c ticketSerach = (Ticket_Serach__c ) TestDataFactory.createSObject(
                            new Ticket_Serach__c (Evaluation_Investigation_Task__c = task.Id
                                
                                                 ), 
                            true
         );
         System.assertEquals('Ticket_Description__c', [SELECT Ticket_Description__c FROM Ticket_Serach__c  WHERE Id =: ticketSerach.Id].Ticket_Description__c );
    }
}