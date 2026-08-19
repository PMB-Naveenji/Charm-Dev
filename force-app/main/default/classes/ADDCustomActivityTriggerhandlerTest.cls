/* 
* @why  : ADDCustomActivityTriggerhandlerTest class for the ADDCustomActivityTriggerhandler,Activity_AuditTrigger
* @when : CreatedDate : 05-SEPTEMBER-2018         
* @what : Class to Handle Different scenarios from ADDCustomActivityTriggerhandler,Activity_AuditTrigger
--------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    05-SEP-2018            Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    28-DEC-2020            TWD Upgrade issue          Added testActivityWF() to test Wf logic.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
public class ADDCustomActivityTriggerhandlerTest {
        /**
* @Method       :  
* @Description  :   To test the Activity_AuditTrigger functionality.
* @Return       : N/A
* @Params       : N/A
**/ 
    @IsTest
    public static void testADDCustomActivityTriggerHandler(){
        Activity__c activityRecord = new Activity__c(Work_Done_Likely_Cause__c = 'Yes');
        Activity__c testActivity;

        Test.startTest();
        insert activityRecord;
        Id activityId = activityRecord.Id;
        TicketUpdateUtility.executeFlag = true;

        update activityRecord;
        testActivity = [
                SELECT Work_Done_Likely_Cause__c
                FROM Activity__c
                WHERE Id =:activityRecord.Id
        ];

        delete activityRecord;
        Test.stopTest();

        System.assertNotEquals(null, activityId);
        System.assertEquals('Yes', testActivity.Work_Done_Likely_Cause__c);
        System.assertEquals(0, [SELECT COUNT() FROM Activity__c]);
    }
    
    /*
    * @Method       : testADDCustomActivityTriggerHandler.
    * @Description  : To test the ADDCustomActivityTriggerhandler class functionality replaced from WF: Update Work Done Code & Description and code
    *                 and Update External Id.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testActivityWF(){
        Activity__c activityRecord = new Activity__c(Work_Done_Likely_Cause__c = 'Yes', Work_Done_Code__c  = 'TEST', Work_Done_Description__c = 'DONE');
        insert activityRecord;
        System.assertEquals('TEST DONE', [SELECT Work_Done_Code_and_Description__c FROM Activity__c WHERE Id =: activityRecord.Id].Work_Done_Code_and_Description__c );
        System.assertEquals(activityRecord.Id, [SELECT External_ID__c FROM Activity__c WHERE Id =: activityRecord.Id].External_ID__c );
    }
}