/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* ADDTrendItemHandlerTest class is test class for ADDTrendItemHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @createdDate:    2018-10-17
* @copyright (c): (2018 - 2019) Abbott CHaRM, Incorporated. All rights are reserved.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* --------------------------------------------------------------------------------------------------------------------------------------
*   Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer               Date                  Modification ID           Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oober                   10-June-2020           N/A                      Updated code part, which is related to Users' insertion. 
                                                                            This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                            error during deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   05-JAN-2020            TWD Upgrade issue        Added method testWfLogic().
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class ADDTrendItemHandlerTest {
    
    //Method to create test data
    @testSetup static void setupData() {
        
        // Create Application Setup data
        
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true); 
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
      	User u = (User) TestDataFactory.createSObject(new User(Alias = 'standt', 
                                                               Email='raj@test.com', 
                                                               Belongs_to_Text__c = 'TRE9',
                                                               Is_ooo__c = False,
                          									   EmailEncodingKey='UTF-8', 
                                                               LastName='Testing1234', 
                                                               LanguageLocaleKey='en_US', 
                          									   LocaleSidKey='en_US', ProfileId = p.Id, 
                          									   TimeZoneSidKey='America/Los_Angeles', 
                                                               UserName='hiii@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10)), 
                                                      true);
        
        //Create Trend Item
        Id thresholdRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Trend_Item__c' AND DeveloperName = 'Thresholds'].Id;
        Trend_Item__c trendItemRecord = (Trend_Item__c) TestDataFactory.createSObject(new Trend_Item__c(Trend_Review_Evaluator__c = u.Id,CMPL123_WF_Action__c = '',Has_Trend_Item_Product_Child__c = True, recordTypeId = thresholdRTId), true);
        
    } 
    
    //Method to cover beforeUpdate method in ADDTrendItemHandler Class
    @isTest static void beforeTrendItemUpdate() {
        
		//Update TrendItem to check for "Trend_Item_Product_Error"
        Trend_Item__c trendItemRecord = [SELECT Id, CMPL123_WF_Action__c FROM Trend_Item__c LIMIT 1];
        trendItemRecord.CMPL123_WF_Action__c = 'Activate';
        try{
            TestDataFactory.updateSObject(trendItemRecord); 
        }catch(Exception e){
           System.assertEquals(true,  String.valueOf(e.getMessage()).containsIgnoreCase('At least one Trend Item - Products child record is required before activating'));
        }

        //Update CMPL123_WF_Action__c to empty
		Trend_Item__c trendItRecord = [SELECT Id, CMPL123_WF_Action__c, Trend_Item_Type__c FROM Trend_Item__c LIMIT 1];
        trendItRecord.CMPL123_WF_Action__c = '';
        TestDataFactory.updateSObject(trendItRecord);
        
        //Update TrendItem to check for "Trend_Item_Issue_Code_Error"
        Trend_Item__c trendItemRec = [SELECT Id, CMPL123_WF_Action__c, Trend_Item_Type__c FROM Trend_Item__c LIMIT 1];
        
        //Create Tend Item Product
        Trend_Item_Product__c trendItemProd = (Trend_Item_Product__c)  TestDataFactory.createSObject(new Trend_Item_Product__c(Trend_Item__c = trendItemRec.Id), true);
        trendItemRec.CMPL123_WF_Action__c = 'Activate';
        trendItemRec.Trend_Item_Type__c = 'Process';
        
        try{
           TestDataFactory.updateSObject(trendItemRec);  
        }catch(Exception e){
           System.assertEquals(true,  String.valueOf(e.getMessage()).containsIgnoreCase('At least one Trend Item - Issue Code child record is required'));
        }
        
        //Update CMPL123_WF_Action__c to empty
		Trend_Item__c trendItRecor = [SELECT Id, CMPL123_WF_Action__c, Trend_Item_Type__c FROM Trend_Item__c LIMIT 1];
        trendItRecor.CMPL123_WF_Action__c = '';
        TestDataFactory.updateSObject(trendItRecor);
        
        //Update TrendItem to check for "Trend_Item_Trend_Buckets_Error"
        Trend_Item__c trendItemReco = [SELECT Id, Trend_Item_Type__c  FROM Trend_Item__c LIMIT 1];
        trendItemReco.Trend_Item_Type__c = 'Assay';
        trendItemReco.CMPL123_WF_Action__c = 'Activate';
        
        try{
            TestDataFactory.updateSObject(trendItemReco); 
        }catch(Exception e){
           System.assertEquals(true,  String.valueOf(e.getMessage()).containsIgnoreCase('At least one Trend Item - Trend Buckets child record is required before activating'));
        }
    }
   
    //Method to cover before/after delete method in ADDTrendItemHandler Class
    @isTest static void befAfterTrendItemDelete() {
        
        Trend_Item__c trendItemReco = [SELECT Id, Trend_Item_Type__c  FROM Trend_Item__c LIMIT 1];
        TestDataFactory.deleteSObject(trendItemReco);
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
        Trend_Item__c trendItemRecord = [SELECT Id, CMPL123_WF_Action__c FROM Trend_Item__c LIMIT 1];
        //WF: Workflow - Activate
        Trend_Item_Product__c trendItemProd = (Trend_Item_Product__c)  TestDataFactory.createSObject(new Trend_Item_Product__c(Trend_Item__c = trendItemRecord.Id), true);
        CMPL123CME__Complaint_Code__c ccode = (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(), true);
        //Trend Item - Trend Bucket (Trend_Item__c) child
        Trend_Item_Trend_Bucket__c trndBucket = (Trend_Item_Trend_Bucket__c) TestDataFactory.createSObject(
                new Trend_Item_Trend_Bucket__c(
                        Trend_Item__c = trendItemRecord.Id,
                        Trend_Bucket_Code__c = ccode.Id)
                , true);
        trendItemRecord.CMPL123_WF_Action__c = 'Activate';
        trendItemRecord.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
        update trendItemRecord;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Activated_By__c FROM Trend_Item__c WHERE Id =: trendItemRecord.Id].Activated_By__c);
        
        //WF: Workflow - Inactivate
        trendItemRecord.CMPL123_WF_Action__c = 'Inactivate';
        update trendItemRecord;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Inactivated_By__c FROM Trend_Item__c WHERE Id =: trendItemRecord.Id].Inactivated_By__c);
        
        //WF: Workflow - Reactivate
        trendItemRecord.CMPL123_WF_Action__c = 'Reactivate';
        update trendItemRecord;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Reactivated_By__c FROM Trend_Item__c WHERE Id =: trendItemRecord.Id].Reactivated_By__c);
    }
}