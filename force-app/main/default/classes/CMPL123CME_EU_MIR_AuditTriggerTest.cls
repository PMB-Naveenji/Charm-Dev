/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2019  Capgemini.
 * @What  : CMPL123CME_EU_MIR_AuditTriggerTest
 * @Why   : To Handle code coverage for CMPL123CME_EU_MIR_123Trigger trigger on CMPL123CME__EU_MIR__c object.
 * @When  : 23-OCT-2019
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date           Modification ID     Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                 23-SEP-2019    Sprint 4            Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          11-JUL-2023    CHaRM R3.1          Fixed crash in testTriggerOperations.
 * Rewrote testTriggerOperations so that it had meaningful assertions and more code coverage.
 * Not related to any IPDR.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */
@IsTest
public with sharing class CMPL123CME_EU_MIR_AuditTriggerTest {
    /**
     * @revision R3.1, Larry: Made a MedEval by necessity. Made a Registered Site
     * for code coverage.
     */
    @TestSetup
    static void makeData(){
        Country__c country = (Country__c) TestDataFactory.createSObject(
            new Country__c (
                Name = 'USA'
            ),
            false
        );
        insert new SObject[]{
            country,
            TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(
                CMPL123CME__Type__c = 'STATE CODE',
                Name = 'NI'
            ), false),
            TestDataFactory.createSObject(new CMPL123CME__Complaint_Code__c(
                CMPL123CME__Type__c = 'STATE CODE'
            ), false)
        };

        CMPL123CME__Registered_Site__c regSite = (CMPL123CME__Registered_Site__c)
        TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(
            CMPL123CME__G1_Contact_Office_Region_State__c = 'NA',
            Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
            MIR_MFR_Country__c = country.Id
        ), false);
        Country_Submission_Type__c countrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
        new Country_Submission_Type__c(
            Name = '30 Days',
            Country__c = country.Id,
            Calendar_Days__c = 30
        ), false);
        insert new SObject[]{ regSite, countrySubmissionType };

        // R3.1, Larry: Made a Ticket for a MedEval
        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint)
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaintRecord = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c (
                RecordTypeId = complaintRecTypeId,
                CMSNext_Ticket_Number__c = '12345',
                CMSNext_Ticket_ID__c = '5975764pdhujiu7ueopfecgeo'
            ),
            true
        );
        // R3.1, Larry: Made a MedEval for both EU MIRs. They seem to be required now.
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
            new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = complaintRecord.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_Regulatory,
                Reportability__c = AspenConstants.REPORTABILITY_NO,
                Reportability_Category__c = 'RCML',
                Reportability_Rationale__c = 'Because there is sand in my shoe'
            ),
            true
        );
        
        List<CMPL123__Product__c> productList = new List<CMPL123__Product__c>{
            (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'test',
                Registered_Site__c = regSite.Id
            ), false),
            (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'test2',
                Registered_Site__c = regSite.Id
            ), false)
        };
        insert productList;

        List<Product_Ticket__c> ptJuncList = new List<Product_Ticket__c>{
            (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = productList[0].Id,
                Event_Ticket__c = complaintRecord.Id
            ), false),
            (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = productList[1].Id,
                Event_Ticket__c = complaintRecord.Id
            ), false)
        };
        insert ptJuncList;
    }

    /**
     * Tests basic trigger operations
     * 
     * Complex interactions and business logic is tested from classes such as
     * EUMIRTriggerHandlerTest.
     * @revision R3.1, Larry: Fixed crash caused by trying to insert an EU MIR
     * without a MedEval. Renamed from "test". Replaced all assertions so
     * that they all have some sort of meaning.
     */
    @IsTest
    public static void testTriggerOperations() {
        // R3.1, Larry: Moved most record creations into a dedicated testSetup method.
        // Queries are merged where possible, but they might be leveraging
        // unused Lookup fields, or borrowing record Ids which should not be shared.
        //
        // This gives code coverage for the before-insert loop which gathers data
        // for intialEuMirFieldUpdateOnInsert, but does not test that method's
        // functionality. Functional testing seems to be accomplished in
        // EUMIRTriggerHandlerTest's testMirFieldUpdateForProductType method.
        CMPL123CME__Questionnaire__c medEval = [
            SELECT Id, CMPL123CME__Complaint__c
            FROM CMPL123CME__Questionnaire__c
            LIMIT 1];
        List<Product_Ticket__c> ptJuncList = [
            SELECT Id,
            Product__r.Registered_Site__c,
            Product__r.Registered_Site__r.MIR_MFR_Country__c
            FROM Product_Ticket__c];

        // R3.1, Larry: Changed var name to better represent the record's purpose.
        // Overhauled most field assignments:
        // Action_on_Follow_Up_Awareness_Date__c is now required for Closed-Done EU MIRs.
        // CMPL123CME__Type_of_Report__c is set to test coverage for inserting an Initial EU MIR.
        // Date_Due__c is set because that will be non-null when an Initial EU MIR is inserted.
        // Follow_Up_Required__c is now required for Closed-Done EU MIRs.
        // MedicalEvaluation__c is now required to insert any EU MIR.
        // Voided_By__c is removed since that is for Closed-Voided EU MIRs.
        // Voided_On__c is removed since that is for Closed-Voided EU MIRs.
        CMPL123CME__EU_MIR__c euMirInitial =
        (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
            new CMPL123CME__EU_MIR__c(
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done,
                CMPL123CME__Type_of_Report__c = AspenConstants.STR_Initial_Report,
                Date_Due__c = System.Today() + 120,
                Follow_Up_Required__c = AspenConstants.STR_Yes,
                MedicalEvaluation__c = medEval.Id,
                Product__c = ptJuncList[0].Id,
                CMPL123CME__Complaint__c = medEval.CMPL123CME__Complaint__c,
                Registered_Site__c = ptJuncList[0].Product__r.Registered_Site__c,
                Country__c = ptJuncList[0].Product__r.Registered_Site__r.MIR_MFR_Country__c
            ),
            true
        );

        // Make an EU MIR as though it was generated from EUMIRTriggerHandler's makeFollowUps.
        // R3.1, Larry: Now sets Type of Report and Parent MIR to make the record
        // look more like a follow-up. Sets WF Status because that should be required.
        // No longer sets the "Voided" fields because those are only for Closed-Voided records.
        CMPL123CME__EU_MIR__c euMirFollowUp =
        (CMPL123CME__EU_MIR__c) TestDataFactory.createSObject(
            new CMPL123CME__EU_MIR__c(
                //RecordTypeId = complaintRecTypeId,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                Initial_MIR__c = euMirInitial.Id,
                Parent_MIR__c = euMirInitial.Id,
                MedicalEvaluation__c = medEval.Id,
                CMPL123CME__Type_of_Report__c = AspenConstants.STR_Follow_Up_Report
            ),
            true
        );

        euMirFollowUp.Product__c = ptJuncList[0].Id;
        update euMirFollowUp;
        euMirFollowUp = [SELECT Id, Product__c FROM CMPL123CME__EU_MIR__c WHERE Id = :euMirFollowUp.Id];
        Assert.areEqual(ptJuncList[0].Id, euMirFollowUp.Product__c,
            'Failed to update the EU MIR');

        // Note: Delete and undelete are not defined as trigger operations that
        // the Apex Trigger handles. If they were, the managed package might
        // reject one or both of these operations. The test(s) would need to be updated.
        delete euMirFollowUp;
        Assert.areEqual(0, [SELECT COUNT() FROM CMPL123CME__EU_MIR__c WHERE Id = :euMirFollowUp.Id],
            'Failed to delete the EU MIR');

        undelete euMirFollowUp;
        Assert.areEqual(1, [SELECT COUNT() FROM CMPL123CME__EU_MIR__c WHERE Id = :euMirFollowUp.Id],
            'Failed to undelete the EU MIR');
    }
}