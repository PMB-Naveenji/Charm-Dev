/* 
* @why  : ADDReturnHandlerTest class for the Return_AuditTrigger,
* @when : CreatedDate : 29-AUG-2018        ModifiedDate : 06-SEPTEMBER-2018
* @what : Class to Handle Different scenarios from Return_AuditTrigger.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    10-JUN-2020            N/A                  Updated code part, which is related to Users' insertion.
*                                                                        This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                        deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    06-JAN-2021            TWD Upgrade issue     Added Logic to test WF rules that are moved to apex
*  --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDReturnHandlerTest {
    //Method to create test data
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c complaintRecord = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(), true);

        User user = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ,
            Alias = 'add' ,
            Email = 'standarduser@test.com' ,
            EmailEncodingKey = 'UTF-8' ,
            LastName = 'add translation_coordinator123' ,
            LanguageLocaleKey = 'en_US' ,
            LocaleSidKey = 'en_US' ,
            TimeZoneSidKey = 'America/Los_Angeles' ,
            Belongs_to_Text__c = 'RA16',
            Is_ooo__c = false,
            UserName = 'testaspen@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);
        
        // Create Return
        Return__c returnRecord = (Return__c) TestDataFactory.createSObject(new Return__c(Ticket__c = complaintRecord.Id, Assignee_Name__c = user.Id), true);
        
        ADD_App_Settings__c appSetting = new ADD_App_Settings__c();
        appSetting.Restrict_Workflow_Updates__c = false;
        appSetting.Name = 'User';
        appSetting.Restrict_Triggers__c = false;
        appSetting.Restrict_Validation_Rules__c = true;
        insert appSetting;
    }
    
    /**
* @Method       :  
* @Description  :   To test the Return_AuditTrigger functionality.
* @Return       : N/A
* @Params       : N/A
**/    
    static testmethod void returnTriggerHandlerTest(){
        //Query Return
        Return__c returnObj = [SELECT Id, CMPL123_WF_Status__c, Ticket__c FROM Return__c LIMIT 1];
        returnObj.CMPL123_WF_Status__c = 'Closed-Void';
        TestDataFactory.updateSObject(returnObj);
        System.assertEquals('Closed-Void', [SELECT Id, CMPL123_WF_Status__c FROM Return__c LIMIT 1].CMPL123_WF_Status__c);
        DELETE returnObj;
        System.assertEquals(new List<Return__c>(), [SELECT Id FROM Return__c LIMIT 1]);
    }
    /*
    * @Method       : testWFlogic
    * @Description  : Test logic from disabled WF rules
    * @Return       : N/A
    * @Params       : N/A
    */ 
    @isTest static void testWFlogic(){
        // WF: Autoset Registration Number
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        complaint.CMSNext_Ticket_Number__c = '123456';
        update complaint;
        Return__c returnRecord = (Return__c) TestDataFactory.createSObject(new Return__c(Ticket__c = complaint.Id, Assignee_Name__c = UserInfo.getUserId()), true); 
        System.assertEquals('123456(Inquiry)', [SELECT Registration_Number__c FROM Return__c WHERE Id =: returnRecord.Id].Registration_Number__c);

        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        CMPL123CME__Complaint__c service = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Complaint_Demotion_rationale__c = '',
                Demotion_rationale__c = '',
                Complaint_Demoted_By__c = UserInfo.getName(),
                Complaint_Demotion_Date__c = System.Now(),
                Division__c  = 'ADD',
                pRE_Status__c  = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = serviceRTId,
                Service_Type__c = 'Planned',
                Business_Unit__c  = 'IA-CC',
                Ticket_Type__c = 'Service',
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                CMSNext_Ticket_Number__c = '12345678',
                CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
                Trending_issue_Bucket__c = 'ProdEvel',
                Receipt_Date__c = System.today() - 5
        ), true);
        returnRecord = (Return__c) TestDataFactory.createSObject(new Return__c(Ticket__c = service.Id, Assignee_Name__c = UserInfo.getUserId(), CMPL123_WF_Status__c  = 'Opened'), true);
        System.assertEquals('12345678(Planned Service)', [SELECT Registration_Number__c FROM Return__c WHERE Id =: returnRecord.Id].Registration_Number__c);
        //WF: Update 123 workflow
        System.assertEquals('RETURN_WORKFLOW', [SELECT CMPL123Rule_Key_Value__c FROM Return__c WHERE Id =: returnRecord.Id].CMPL123Rule_Key_Value__c);
        //WF: Workflow - Close  
        returnRecord.CMPL123_WF_Action__c = 'Close';
        returnRecord.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
        returnRecord.CMPL123_WF_Action_Performed_On__c = date.today();
        update returnRecord;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Closed_By__c FROM Return__c WHERE Id =: returnRecord.Id].Closed_By__c);
        //WF: Workflow - Reopen 
        returnRecord.CMPL123_WF_Action__c = 'Reopen';
        update returnRecord;
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Reopened_By__c FROM Return__c WHERE Id =: returnRecord.Id].Reopened_By__c);
        
    }
}