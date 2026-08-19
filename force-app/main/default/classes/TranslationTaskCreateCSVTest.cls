/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TranslationTaskCreateCSVTest.
* @Why   : Test class to handle different scenarios from TranslationTaskCreateCSV class.
* @When  : 05-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  05-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest()
public class TranslationTaskCreateCSVTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){

        // Query RecordType for Translation_Task__c and CMPL123CME__Complaint__c objects for 'Text Translation' and 'Complaint' Record types respectively
        String textTransTaskRecTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId();
        String attTransTaskRecTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Attachment Translation').getRecordTypeId();
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();

        //Create CMPL123CME__Complaint__c  record
        CMPL123CME__Complaint__c comp = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new
                    CMPL123CME__Complaint__c(RecordTypeId = compRecTypeId,
                    CMSNext_Ticket_Number__c = '0600560C1333015'), true);

        //Create Translation_Task__c  record
        Translation_Task__c translationTaskRecord = (Translation_Task__c) TestDataFactory.createSObject(new
                                    Translation_Task__c(CMPL123_WF_Status__c = 'In Process',
                                    RecordTypeId = textTransTaskRecTypeId,urgency__c = 'Urgent',
                                     Parent_Ticket__c = comp.id),
                                     true);

        Translation_Task__c translationTaskRecOpened = (Translation_Task__c) TestDataFactory.createSObject(new
                                    Translation_Task__c(CMPL123_WF_Status__c = 'Opened',
                                    RecordTypeId = attTransTaskRecTypeId,urgency__c = 'Urgent',
                                     Parent_Ticket__c = comp.id),
                                     true);

        //Create Translation_Item__c  record
        Translation_Item__c translationItemRecord = (Translation_Item__c) TestDataFactory.createSObject(new
                                           Translation_Item__c(Translation_Task__c = translationTaskRecord.Id,
                                           Translated__c = null,Native__c = '栗原市立若柳病院\n',
                                           Field_Name__c = 'test,Data'),
                                       true);

    }

    /*
    * @Method       : generateTranslationTaskCreateCSVTest.
    * @Description  : To insert attachment for Translation_Task__c object record.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void generateTranslationTaskCreateCSVTest(){
        test.startTest();
        Translation_Task__c transTaskRecInProcess = [SELECT CMPL123_WF_Status__c,RecordTypeId,urgency__c,
                                                     Parent_Ticket__c FROM Translation_Task__c WHERE CMPL123_WF_Status__c = 'In Process' ];

        Translation_Task__c transTaskRecOpened = [SELECT CMPL123_WF_Status__c,RecordTypeId,urgency__c,
                                                     Parent_Ticket__c FROM Translation_Task__c WHERE CMPL123_WF_Status__c = 'Opened' ];
        String generatedCSV = TranslationTaskCreateCSV.generateTranslationTaskCreateCSV(transTaskRecInProcess.Id);
        System.assertEquals('Success', generatedCSV);
        //String generatedCSVblank = TranslationTaskCreateCSV.generateTranslationTaskCreateCSV('');
        //System.assertEquals('No Records Found', generatedCSVblank);  translationTaskRecord2
        String generatedCSVblank = TranslationTaskCreateCSV.generateTranslationTaskCreateCSV(transTaskRecOpened.Id);
        System.assertEquals('No Records Found', generatedCSVblank);
        Attachment att = [SELECT ID,Name,ParentId FROM Attachment WHERE ParentId = :transTaskRecInProcess.Id];
        System.assertEquals(att.ParentId,transTaskRecInProcess.Id);
        test.stopTest();
    }
}