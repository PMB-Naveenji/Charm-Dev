/* 
* @why  : ADDKILogTriggerHandlerTest class for the ADDKILogTriggerHandler,
* @when : CreatedDate : 29-OCT-2018         
* @what : Class to Handle Different scenarios from ADDKILogTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                29-OCT-2018           Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                28-DEC-2020           TWD Upgrade issue         Related to WF Step issue, rules with field update moved to this handler.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDKILogTriggerHandlerTest {
    @testSetup static void setup(){
        // Create Application Setup data
        //ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true); 
        
        //Create KI_Log__c
        KI_Log__c objKILog = (KI_Log__c) TestDataFactory.createSObject(new KI_Log__c  (
            Type__c = 'Product Evaluation',
            Division__c = 'ADD',
            Trending_Issue_Bucket__c = 'ACON' ),true);   
    }
    
    
    /**
* @Method       : testADDKILogTriggerHandlerTest
* @Description  : To test the ADDKILogTriggerHandlerTest funtionality.
* @Return       : N/A
* @Params       : N/A
**/ 
    
    @isTest
    public static void testADDKILogTriggerHandlerTest(){
        KI_Log__c objKILog = [SELECT id,Trending_Issue_Bucket__c FROM KI_Log__c WHERE Type__c = 'Product Evaluation'];
        String str = objKILog.Trending_Issue_Bucket__c;
        objKILog.Trending_Issue_Bucket__c ='DMGD';
        UPDATE objKILog;
        System.assertNotEquals(objKILog.Trending_Issue_Bucket__c, str);
        DELETE objKILog;
        System.assertEquals(new List<KI_Log__c>(), [SELECT id,Trending_Issue_Bucket__c FROM KI_Log__c WHERE Type__c = 'Product Evaluation']);
    }

    /*
    * @Method       : testDateAutoset.
    * @Description  : To test the ADDKILogTriggerHandler class functionality. WF: Autoset Inactived On Field Date/Time logic moved to trigger handler
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testDateAutoset(){
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        KI_Log__c objKILog = (KI_Log__c) TestDataFactory.createSObject(new KI_Log__c  (
            Type__c = 'Product Evaluation',
            Division__c = 'ADD',
            Status__c = 'Inactive',
            Trending_Issue_Bucket__c = 'ACON' ),true);
        System.assertNotEquals(null, [SELECT Inactived_On__c FROM KI_Log__c WHERE Id =: objKILog.Id].Inactived_On__c );
        objKILog = (KI_Log__c) TestDataFactory.createSObject(new KI_Log__c  (
            Type__c = 'Product Evaluation',
            Division__c = 'ADD',
            Status__c = 'Active',
            Trending_Issue_Bucket__c = 'ACON' ),true);
        System.assertEquals(null, [SELECT Inactived_On__c FROM KI_Log__c WHERE Id =: objKILog.Id].Inactived_On__c );
        appConfig.Restrict_Workflow_Updates__c = true;
        update appConfig;
        objKILog = (KI_Log__c) TestDataFactory.createSObject(new KI_Log__c  (
            Type__c = 'Product Evaluation',
            Division__c = 'ADD',
            Status__c = 'Inactive',
            Trending_Issue_Bucket__c = 'ACON' ),true);
        System.assertEquals(null, [SELECT Inactived_On__c FROM KI_Log__c WHERE Id =: objKILog.Id].Inactived_On__c );
        
    }

}