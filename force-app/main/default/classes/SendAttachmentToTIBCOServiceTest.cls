/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SendAttachmentToTIBCOServiceTest.
* @Why   : To test 'SendAttachmentToTIBCOService' class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    30-MAY-2019            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oober                    10-JUN-2020            N/A                           Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                                   error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class SendAttachmentToTIBCOServiceTest {
    /*
    * @Method       : sendAttachmentTest.
    * @Description  : To test 'sendAttachment()' method.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void sendAttachmentTest() {
        //Create User
        User testUser = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
                LastName = 'lastname',
                Email = 'emailid@test.com',
                Username = 'user123@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'CompanyXXX',
                Title = 'Title',
                Alias = 'Alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);

        //Query RecordType
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        String transTaskRecTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId();

        //Create Complaint Record
        CMPL123CME__Complaint__c comp = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new
                CMPL123CME__Complaint__c(RecordTypeId = compRecTypeId
                ), true);

        //Create Translation Task Record
        Translation_Task__c translationTaskRecord = (Translation_Task__c) TestDataFactory.createSObject(new
                Translation_Task__c(CMPL123_WF_Status__c = 'In Process',
                        RecordTypeId = transTaskRecTypeId, urgency__c = 'Urgent', Assignee_Name__c = testUser.id,
                        Parent_Ticket__c = comp.id),
                true);
        //Create Attachment__c Task Record
        Attachment__c att = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(Name = 'TranslationItemAttachment',
                Translation_Task__c = translationTaskRecord.id,
                Attachment_Type__c = 'Translation'
        ), true);

        // Send callout from test context to check exception handling
        Test.startTest();
        System.runAs(testUser) {
            SendAttachmentToTIBCOService.sendAttachment(att);
        }
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Error_Type__c = 'TIBCO Attachment Service Call Failed'];
        System.assertEquals(0, errorLogs.size());
        for (Integer code : new List<Integer> {300, 304, 400, 401, 403, 404, 405, 415, 500}) {
            System.assert(SendAttachmentToTIBCOService.resolveStatusCodeToText(code).length() > 0);
        }
        Test.stopTest();
    }
}