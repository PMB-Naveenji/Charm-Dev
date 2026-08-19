/* 
* @why  : ADDActionTaskTriggerhandlerTest class for the ADDActionTaskTriggerhandler,
* @when : CreatedDate : 25-OCT-2018         
* @what : Class to Handle Different scenarios from ADDActionTaskTriggerhandler.
* --------------------------------------------------------------------------------------------------------------------------------------
*   Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID         Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   05-JAN-2020            TWD Upgrade issue        Added method testWfLogic().
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class ADDActionTaskTriggerhandlerTest {
     @testSetup static void setup(){
       Action_Task__c objActionTask = (Action_Task__c) TestDataFactory.createSObject(new Action_Task__c  (
           Action_Description__c = 'User should enter proper value',
           Action_Type__c = '21CR806',
           Assignee__c = UserInfo.getUserId(),
           CMPL123Rule_Key_Value__c = 'HAZARD_ASSESSMENT_ADD_WORKFLOW',
           CMPL123_WF_Status__c = 'Opened'),true);
     }


    /**
* @Method       : taskTriggerHandlerTest
* @Description  : To test the ActionTaskTriggerHandler funtionality.
* @Return       : N/A
* @Params       : N/A
**/

    @isTest
    public static void taskTriggerHandlerTest(){
       Action_Task__c objActionTask = [SELECT id FROM Action_Task__c WHERE CMPL123_WF_Status__c = 'Opened'];
       UPDATE objActionTask;
       System.assertEquals(objActionTask.Id, [SELECT id FROM Action_Task__c WHERE CMPL123_WF_Status__c = 'Opened'].Id);
       DELETE objActionTask;
       System.assertEquals(new List<Action_Task__c>(), [SELECT Id FROM Action_Task__c WHERE Id =:objActionTask.Id]);
    }
    
    /*
    * @Method       : testWfLogic
    * @Description  : To test the logic removed from WF and added to apex.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testWfLogic() {
        Action_Task__c objActionTask = [SELECT id FROM Action_Task__c WHERE CMPL123_WF_Status__c = 'Opened'];
        //WF: Regulatory Evaluation Due Date    
        objActionTask.Action_Type__c = 'Regulatory Evaluation, 21CR806';
        update objActionTask;
        System.assertEquals(date.today().addDays(10), [SELECT Date_Due_Date__c FROM Action_Task__c WHERE Id =: objActionTask.Id].Date_Due_Date__c);
        //WF: Workflow - Complete   
        objActionTask.Action_Activity_Completed__c = 'TEST';
        objActionTask.CMPL123_WF_Action__c = 'Complete';
        objActionTask.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
        update objActionTask;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Completed_By__c FROM Action_Task__c WHERE Id =: objActionTask.Id].Completed_By__c);
        
        //WF: Workflow - Reopen
        objActionTask.CMPL123_WF_Action__c = 'Reopen';
        objActionTask.CMPL123_WF_Action_Performed_On__c = date.today();
        update objActionTask;
        System.assertNotEquals(null, [SELECT Reopen_Date__c FROM Action_Task__c WHERE Id =: objActionTask.Id].Reopen_Date__c);
        
        //WF: Workflow - Submit
        objActionTask.CMPL123_WF_Action__c = 'Promote';
        update objActionTask;
        System.assertNotEquals(null, [SELECT Assignee_Date__c FROM Action_Task__c WHERE Id =: objActionTask.Id].Assignee_Date__c);
    }   
}