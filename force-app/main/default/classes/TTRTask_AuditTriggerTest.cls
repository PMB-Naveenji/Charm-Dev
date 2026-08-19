/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TTRTask_AuditTriggerTest.
* @Why   : To test functionality of TTRTask_AuditTrigger trigger.
* @When  : 31-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  31-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                  29-DEC-2020            TWD Upgrade issue               Added method triggerWFTest() to test WF logic.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class TTRTask_AuditTriggerTest {
    @isTest
    static void triggerEventsTest() {
        Tracking_Trending_Review_Task__c ttrTask = (Tracking_Trending_Review_Task__c) TestDataFactory.createSObject(
                new Tracking_Trending_Review_Task__c(), true);
        update ttrTask;
        delete ttrTask;
        System.assert(0 == [SELECT COUNT() FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id]);
    }
    
    /*
    * @Method       : triggerWFTest.
    * @Description  : To test logic moved from WF for Tracking_Trending_Review_Task__c.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void triggerWFTest() {
       Tracking_Trending_Review_Task__c ttrTask = (Tracking_Trending_Review_Task__c) TestDataFactory.createSObject(
                new Tracking_Trending_Review_Task__c(CMPL123_WF_Action__c = 'Submit'), true);
       System.assertNotEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Submitted_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Submitted_By__c);                                              
       
       ttrTask = (Tracking_Trending_Review_Task__c) TestDataFactory.createSObject(
                new Tracking_Trending_Review_Task__c(CMPL123_WF_Action__c = 'Send Back to In Process', 
                                                     CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(), 
                                                     CMPL123_WF_Action_Performed_On__c = datetime.now()), true);
       System.assertEquals(null, [SELECT Submitted_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Submitted_By__c );                                              
       ttrTask.CMPL123_WF_Action__c = 'Submit';
       update ttrTask;
       System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Submitted_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Submitted_By__c);                                              
       ttrTask.CMPL123_WF_Action__c = 'Submit For Approval';
       ttrTask.Adverse_Trend__c = 'No';
       update ttrTask;
       System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Submitted_for_Approval_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Submitted_for_Approval_By__c );                                              
       ttrTask.CMPL123_WF_Action__c = 'Reject';
       ttrTask.Reject_Rationale__c = 'Rejected';
       update ttrTask;
       System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Reject_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Reject_By__c );                                              
       ttrTask.CMPL123_WF_Action__c = 'Void';
       update ttrTask;
       System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Voided_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Voided_By__c );                                              
       ttrTask.CMPL123_WF_Status__c = 'Closed-Done';
       update ttrTask;
       System.assertEquals(null, [SELECT Reject_By__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Reject_By__c ); 
       ttrTask.CMPL123_WF_Action__c = 'Send Back to In Process';
       ttrTask.Submitted_for_Approval_On__c = date.today();
       update ttrTask;
       System.assertEquals(null, [SELECT Submitted_for_Approval_On__c FROM Tracking_Trending_Review_Task__c WHERE Id = :ttrTask.Id].Submitted_for_Approval_On__c );                                              
    }
}