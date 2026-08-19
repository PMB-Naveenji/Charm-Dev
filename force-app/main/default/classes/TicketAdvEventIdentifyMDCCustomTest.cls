/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 14-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    12-OCT-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Charm COE                29-JUN-2026            CHaRM 9.0/IPDR-96    Added 'testCustomValidation_NullToNo' method to test when 
*																	   Was_an_Adverse_Event_Identified__c field changes from Null to No.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class TicketAdvEventIdentifyMDCCustomTest {
    /**
* @Method       : setupData
* @Description  : Create records needed in test method(s)
* @Return       : N/A
* @Params       : N/A
**/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                                         Complaint_Quality_Closure_Date__c = system.now(),
                                         Overall_Reportable_Status__c = 'Reportable'), true);
        
        TestUtil.setupMDC(
            TicketAdvEventIdentifyMDCCustom.class,
            CMPL123CME__Complaint__c.getSObjectType(),
            CMPL123CME__Complaint__c.Was_an_Adverse_Event_Identified__c
        );
    }
    
    /**
* @Method       : test
* @Description  : Contains verification logic
* @Return       : N/A
* @Params       : N/A
**/
    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        Test.startTest();
        complaint.Was_an_Adverse_Event_Identified__c = 'Yes';
        TestDataFactory.updateSObject(complaint);
        
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :complaint.Id
            AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);
        
        TicketQDNumMDCCustom.hasProdEval = true;
        complaint.Was_an_Adverse_Event_Identified__c = 'No';
        TestDataFactory.updateSObject(complaint);
        
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :complaint.Id
            AND CMPL123__Action__c = 'Update'
        ][1].CMPL123__Action__c);
        Test.stopTest();
    }
    
    /**
* @Method       : testCustomValidation_NullToNo
* @Description  : To test when Was_an_Adverse_Event_Identified__c field changes from Null to No.
* @Return       : N/A
* @Params       : N/A
**/    
    @IsTest
    private static void testCustomValidation_NullToNo() {
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        Test.startTest();                        
        complaint.Was_an_Adverse_Event_Identified__c = 'No';
        TestDataFactory.updateSObject(complaint);
        
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :complaint.Id
            AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
        Test.stopTest();
    }
    
}