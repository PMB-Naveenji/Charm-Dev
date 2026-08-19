/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 13-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    14-JUN-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Charm COE     	       29-JUN-2026            CHaRM-9.0/IPDR-165   Added testNullDeletionJustification() to validate that no MDC is 
																	   generated when Deletion_Justification__c is null.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class AttachmnetsDeletionWithQNCMDCTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup () {
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        appConfig.MDC_Generation_Prevention_Minutes__c=10.0;
        update appConfig;
        String inquiryRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        CMPL123CME__Complaint__c ticket = new CMPL123CME__Complaint__c (
                Division__c  = 'ADD',
                pRE_Status__c  = 'Yes',
                Country_of_origin__c  = 'INDIA',
                RecordTypeId = inquiryRTId,
                Business_Unit__c  = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                CMSNext_Ticket_Number__c = '12345',
                Is_Custom_response_child_created__c=true
        );
        insert ticket;

        insert new Attachment__c(
                Name = 'TranslationTaskAttachment',
                Attachment_Type__c = 'Registration',
                Deletion_Justification__c = 'Old',
                Ticket__c = ticket.Id
        );

        TestUtil.setupMDC(
                AttachmnetsDeletionWithQNCMDCLogic.class,
                Attachment__c.getSObjectType(),
                Attachment__c.Deletion_Justification__c
        );
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        Attachment__c attachment = [SELECT Deletion_Justification__c FROM Attachment__c LIMIT 1];

        Test.startTest();
        attachment.Deletion_Justification__c = 'New';
        TestDataFactory.updateSObject(attachment);
        Test.stopTest();
        System.assertEquals('Update', [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: attachment.Id AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);
    }
    /**
* @Method       : testNullDeletionJustification 
* @Description  : Validates No MDC generated when Deletion_Justification__c is null. 
* @Return       : N/A
* @Params       : N/A
**/
    @IsTest
    private static void testNullDeletionJustification() {
        Attachment__c attachment = [SELECT Deletion_Justification__c FROM Attachment__c LIMIT 1];       
        Test.startTest();          
        attachment.Deletion_Justification__c=null;
        TestDataFactory.updateSObject(attachment);        
        Test.stopTest();
        
        System.assertEquals('Update', [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: attachment.Id AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);
    }
}