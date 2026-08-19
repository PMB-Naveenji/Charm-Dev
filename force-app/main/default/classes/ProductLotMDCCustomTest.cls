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
 * Admin                    26-OCT-2018            Work ID / Case ID    Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    10-Jun-2020            N/A                  Updated code part, which is related to Users' insertion.
 *                                                                      This change designed to prevent a 'DUPLICATE_USERNAME' error during
 *                                                                      deployment to Production environment
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    14-JAN-2021            TWD Upgrade          Add new testAdditionalScenarios method. Update setup and
 *                                                                      customValidation method. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             12-JUN-2023            CHaRM R3.1           Fix crash in testCustomValidationPosDivision
 * caused by managed package update. Changed all asserts to be more meaningful. Added a negative test: testCustomValidationNeg.
 * Set isParallel. Not related to any IPDR.
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
@IsTest(isParallel=true)
private class ProductLotMDCCustomTest {
    private static final String PRODUCT_LOT_ONE = '111';
    private static final String PRODUCT_LOT_TWO = '222';
    private static final String PRODUCT_LOT_THREE = '333';
    private static final String ACTION_UPDATE = 'Update';
    private static final String ERROR_EXPECT_MDC = TestUtil.ERROR_POS +
        'Should have made an MDC';

    /**
     * @Method       : setupData
     * @Description  : Create records needed in test method(s)
     * @Return       : N/A
     * @Params       : N/A
     **/
    @TestSetup static void setupData() {

        // Create Complaint
        // R3.1, Larry: Set Overall Reportable Status so that
        // TicketQDNumMDCCustom.isTicketOverallReportable is true
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c)
        TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
            pRE_Status__c = AspenConstants.STR_Yes,
            Country_of_origin__c = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_Opened,
            Overall_Reportable_Status__c = AspenConstants.REPORTABILITY_YES
        ), false);
        CMPL123CME__Complaint__c complaintNotReportable = complaint.clone();
        complaintNotReportable.Overall_Reportable_Status__c = AspenConstants.REPORTABILITY_NO;
        insert new CMPL123CME__Complaint__c[]{ complaint, complaintNotReportable };

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User usr = [SELECT Id FROM User WHERE ProfileId = :profileId AND IsActive = true LIMIT 1];
        System.runAs(usr) {
            // Create Product
            CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c = '123',
                List_Number__c = '12345'
            ), false);

            // R3.1, Larry: Now inserts a MedEval so that TicketQDNumMDCCustom.hasMedEval is true
            insert new SObject[]{
                product,
                TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                    CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                    CMPL123CME__Complaint__c = complaint.Id
                ), false)
            };

            // Create Product Ticket
            Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Product__c = product.Id), true);

            //Get Investigation
            CMPL123CME__Investigation__c objInv = [SELECT Name, Id
                FROM CMPL123CME__Investigation__c WHERE Name != NULL LIMIT 1];

            //Create Product Lot
            // R3.1, Larry: Now sets Division__c so that MDC creation can be tested against
            // this instead of Device_Manufacturing_Date__c . It seems that AuditTrail_Configs made
            // against Dates are causing problems in test methods.
            // Made a third Product/Lot for negative testing.
            Product_Lot__c prodLotOne =
            (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                External_Id__c = PRODUCT_LOT_ONE,
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
                Product_Evaluation_Investigation__c = objInv.Id
            ), false);
            Product_Lot__c prodLotTwo = prodLotOne.clone();
            prodLotTwo.External_Id__c = PRODUCT_LOT_TWO;
            Product_Lot__c prodLotThree = prodLotOne.clone();
            prodLotThree.External_Id__c = PRODUCT_LOT_THREE;
            prodLotThree.Related_Ticket__c = complaintNotReportable.Id;
            insert new Product_Lot__c[]{
                prodLotOne, prodLotTwo, prodLotThree
            };
        }
    }

    /**
     * Helper for all tests that counts how many MDCs exist for the passed record
     * @author R3.1, Larry
     */
    private static Integer getNumMdcs(Product_Lot__c objProductLot) {
        return [
            SELECT COUNT()
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :objProductLot.Id
            AND CMPL123__Action__c = :ACTION_UPDATE
        ];
    }

    /**
     * Pos test(s) for CustomValidation such that MDCs are made for Division
     * @revision: R3.1, Larry: Crashfix. Now verifies that the audit trail entry is
     * made from Division__c instead of Device_Manufacturing_Date__c.
     * Renamed from customValidation since that is confusingly the same name
     * of the method being tested
     **/
    @IsTest
    static void testCustomValidationPosDivision() {
        TestUtil.setupMDC(
            ProductLotMDCCustom.class,
            Product_Lot__c.getSObjectType(),
            Product_Lot__c.Division__c
        );
        Product_Lot__c objProductLot = [
            SELECT Id, Division__c
            FROM Product_Lot__c
            WHERE External_Id__c = :PRODUCT_LOT_ONE];
        Test.startTest();
        objProductLot.Division__c = AspenConstants.DIVISION_MOLECULAR;

        TestDataFactory.updateSObject(objProductLot);
        Assert.areEqual(1, getNumMdcs(objProductLot), ERROR_EXPECT_MDC);

        objProductLot.Division__c = AspenConstants.DIVISION_DIAGNOSTICS;
        // R3.1, Removed these assignments because they are not necessary for
        // the test to work.
        // TicketQDNumMDCCustom.hasMedEval = true;
        // TicketQDNumMDCCustom.isTicketOverallReportable = true;
        TestDataFactory.updateSObject(objProductLot);
        Assert.areEqual(2, getNumMdcs(objProductLot), ERROR_EXPECT_MDC);
        Test.stopTest();
    }

    /**
     * Pos test(s) for CustomValidation such that MDCs are made for Expiration Date Unknown
     * @revision: R3.1, Larry: Renamed from testAdditionalScenarios.
     **/
    @IsTest
    private static void testCustomValidationPosExpireUnknown() {
        TestUtil.setupMDC(
            ProductLotMDCCustom.class,
            Product_Lot__c.getSObjectType(),
            Product_Lot__c.Device_Expiration_Date_Unknown__c
        );
        Product_Lot__c objProductLot = [
            SELECT Id, Device_Expiration_Date_Unknown__c
            FROM Product_Lot__c
            WHERE External_Id__c = :PRODUCT_LOT_TWO];
        Test.startTest();
        objProductLot.Device_Expiration_Date_Unknown__c = true;

        TestDataFactory.updateSObject(objProductLot);
        Assert.areEqual(1, getNumMdcs(objProductLot), ERROR_EXPECT_MDC);

        objProductLot.Device_Expiration_Date_Unknown__c = false;
        // R3.1, Removed these assignments because they are not necessary for
        // the test to work.
        // TicketQDNumMDCCustom.hasMedEval = true;
        // TicketQDNumMDCCustom.isTicketOverallReportable = true;
        TestDataFactory.updateSObject(objProductLot);
        Assert.areEqual(2, getNumMdcs(objProductLot), ERROR_EXPECT_MDC);
        Test.stopTest();
    }

    /**
     * Neg test(s) for CustomValidation for when no MDC should be made
     * 
     * This is accomplished by doing an update on a field which is not audited
     * @author R3.1, Larry
     **/
    @IsTest
    private static void testCustomValidationNeg() {
        Product_Lot__c objProductLot = [
            SELECT Id, CMPL123Rule_Key_Value__c
            FROM Product_Lot__c
            WHERE External_Id__c = :PRODUCT_LOT_THREE];
        Test.startTest();
        objProductLot.CMPL123Rule_Key_Value__c = 'PointlessChange';
        TestDataFactory.updateSObject(objProductLot);
        Assert.areEqual(0, getNumMdcs(objProductLot), TestUtil.ERROR_NEG +
            'Should NOT make an MDC because none of the audited fields were changed, ' +
            'and the parent Ticket is NOT overall-reportable');
        Test.stopTest();
    }
}