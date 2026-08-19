/**
 * -----------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2022 Capgemini
 * @Why   : Test class for ADDTicketUpdateAsync
 * @When  : 26-OCT-2022
 * @Where : From ADDTicketUpdateAsync class.
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Developer              Date                      Modification ID              Description
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           26-OCT-2022               CHaRM R2.2, IPDR 66          Init
 * -----------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           18-JUL-2023               CHaRM R3.1                   Reverted most code since the main class
 * was reverted in R2.2.1. Added testTicketUpdateAsyncBadParams. Not related to an IPDR.
 * -----------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public without sharing class ADDTicketUpdateAsyncTest {
    private static final String EMAIL_INTERNAL = 'intern@test.com';
    private static final String EMAIL_EXTERNAL = 'extern@test.com';
    private static final String PROFILE_EXTERNAL = 'ASPEN Integration';
    private static final String CMSNEXT_NUM_ONE = '0600560C493851';
    private static final String CMSNEXT_NUM_TWO = '0600560C493852';
    private static final String CMSNEXT_NUM_THREE = '0600560C493853';
    private static final String CMSNEXT_NUM_FOUR = '0600560C493854';
    private static final String CMSNEXT_NUM_OTHER = '0600560C49385A';
    private static final String TOO_LONG_LABEL = System.label.CumulativeFieldTooLong;
    private static final String ERROR_TOO_LONG_SCENARIO = TestUtil.ERROR_POS +
        'Expected the field to be replaced with the label';

    /**
     * Factory method that makes Tickets
     * @author R3.1, Larry
     */
    private static CMPL123CME__Complaint__c makeTicket(String cmsNextNum, Boolean alsoInsert) {
        Id rtId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = rtId,
                Division__c  = AspenConstants.DIVISION_DIAGNOSTICS,
                pRE_Status__c  = AspenConstants.STR_Yes,
                Business_Unit__c  = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                Country_of_origin__c = 'USA',
                CMSNext_Ticket_Number__c = cmsNextNum,
                Trending_issue_Bucket__c = 'ACON'
            ),
            alsoInsert
        );
        return complaint;
    }

    private static CMPL123CME__Complaint__c getSetupTicket(String cmsNextNum) {
        return [
            SELECT Id, CMSNext_Ticket_Number__c,
            (SELECT Id FROM CMPL123CME__Investigations__r)
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_Number__c = :cmsNextNum
            WITH SECURITY_ENFORCED
            LIMIT 1];
    }

    @TestSetup
    public static void makeData() {
        Map<String, SObjectField> ticketFieldMap =
            SObjectType.CMPL123CME__Complaint__c.fields.getMap();
        Integer batchLotSerialLen = ticketFieldMap.get('Batch_Lot_Serial__c').getDescribe().getLength();
        Integer productNameLen = ticketFieldMap.get('Product_Name__c').getDescribe().getLength();
        Integer ptListNumLen = ticketFieldMap.get('Product_Ticket_List_Number__c').getDescribe().getLength();
        String longBatchLotSerial = '*'.repeat(batchLotSerialLen);
        String longProductName = '*'.repeat(productNameLen);
        String longPtListNum = '*'.repeat(ptListNumLen);

        // R3.1, Larry: Copied User creation logic from ADDProductTicketTriggerHandlerTest
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(
            new ADD_App_Settings__c(), true);

        final Set<String> ALL_PROFILES = new Set<String>{
            AspenConstants.PROFILE_STD, PROFILE_EXTERNAL
        };
        Map<String, Id> profileNameToId = new Map<String, Id>();
        for (Profile prof : [SELECT Name, Id FROM Profile WHERE Name IN :ALL_PROFILES]) {
            profileNameToId.put(prof.Name, prof.Id);
        }
        // R3.1, Larry: User creation now leverages makeTestUser
        User internUser = TestUtil.makeTestUser(profileNameToId.get(AspenConstants.PROFILE_STD),
            EMAIL_INTERNAL, EMAIL_INTERNAL, false);
        User externUser = TestUtil.makeTestUser(profileNameToId.get(PROFILE_EXTERNAL),
            EMAIL_EXTERNAL, EMAIL_EXTERNAL, false);
        insert new SObject[]{ internUser, externUser };
        
        System.runAs(externUser) {
            TestDataFactory.makeProductWithLongNames(true);
        }

        // Make the first Ticket have one ProdEval child.
        // Make the second Ticket have two ProdEval children.
        // Make the third Ticket have no ProdEval children.
        // Make the fourth Ticket be just like the first, but with long names.
        {
            CMPL123CME__Complaint__c ticket1 = makeTicket(CMSNEXT_NUM_ONE, false);
            CMPL123CME__Complaint__c ticket2 = ticket1.clone();
            // R3.1, Larry: Made CMSNext Number unique between the Tickets.
            // They should be unique, but it didn't seem to cause problems before this fix.
            ticket2.CMSNext_Ticket_Number__c = CMSNEXT_NUM_TWO;
            CMPL123CME__Complaint__c ticket3 = ticket1.clone();
            ticket3.CMSNext_Ticket_Number__c = CMSNEXT_NUM_THREE;
            CMPL123CME__Complaint__c ticket4 = ticket1.clone();
            ticket4.CMSNext_Ticket_Number__c = CMSNEXT_NUM_FOUR;
            ticket4.Batch_Lot_Serial__c = longBatchLotSerial;
            ticket4.Product_Name__c = longProductName;
            ticket4.Product_Ticket_List_Number__c = longPtListNum;
            insert new List<CMPL123CME__Complaint__c>{
                ticket1, ticket2, ticket3, ticket4 };

            CMPL123CME__Investigation__c prodEval1 =
            (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(CMPL123CME__Complaint__c = ticket1.Id),
                false
            );
            CMPL123CME__Investigation__c prodEval2 = prodEval1.clone();
            CMPL123CME__Investigation__c prodEval3 = prodEval1.clone();
            prodEval3.CMPL123CME__Complaint__c = ticket2.Id;
            CMPL123CME__Investigation__c prodEval4 = prodEval1.clone();
            prodEval4.CMPL123CME__Complaint__c = ticket4.Id;
            insert new List<CMPL123CME__Investigation__c>{
                prodEval1, prodEval2, prodEval3, prodEval4 };
        }
    }

    /**
     * Pos/neg tests for ticketUpdateAsync where cumulative fields are too long
     * @author 06-OCT-2022 Larry Resnik
     * @revision 26-OCT-2022 Larry: Migrated from ADDProductTicketTriggerHandlerTest
     * to ADDTicketUpdateAsyncTest
     */
    @isTest
    static void testTicketUpdateAsync() {
        Integer fewestRequiredPt = ADDProductTicketTriggerHandlerTest.getNumProdEvalsToOverflowCumul();

        User usr = [SELECT Id FROM User WHERE Email = :EMAIL_INTERNAL LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            // Create a Complaint to contain one ProdEval and many Product-Tickets
            // R3.1, Larry: Made this Ticket have a unique CMSNext Number from the testSetup Tickets
            CMPL123CME__Complaint__c complaint = makeTicket(CMSNEXT_NUM_OTHER, true);

            // Get Product from testSetup
            CMPL123__Product__c product = [
                SELECT Id, Name, CMPL123__Lot_No__c, List_Number__c
                FROM CMPL123__Product__c
                LIMIT 1
            ];

            // Create enough Product-Tickets to exceed all cumulative field char limits
            List<Product_Ticket__c> ptList =
                new List<Product_Ticket__c>(fewestRequiredPt);
            for (Integer i = 0; i < fewestRequiredPt; i+=1) {
                ptList[i] =
                (Product_Ticket__c) TestDataFactory.createSObject(
                    new Product_Ticket__c(
                        Batch_Lot_Serial__c = product.CMPL123__Lot_No__c,
                        Event_Ticket__c = complaint.Id,
                        Likely_Cause__c = 'Yes',
                        Product__c = product.Id
                    ),
                    false
                );
            }
            insert ptList;

            // Made Product-Tickets, so ProdEvals were made automatically
            List<CMPL123CME__Investigation__c> prodEvalList = [
                SELECT Name, Id, CMPL123_WF_Status__c
                FROM CMPL123CME__Investigation__c
                WHERE CMPL123CME__Complaint__c = :complaint.Id
            ];
            // Fix the new ProdEval WorkFlow Statuses
            for (CMPL123CME__Investigation__c prodEval : prodEvalList) {
                prodEval.CMPL123_WF_Status__c = AspenConstants.STR_Assess;
            }
            update prodEvalList;

            //Create Product Lot
            List<Product_Lot__c> prodLotList =
                new List<Product_Lot__c>(fewestRequiredPt);
            for (Integer i = 0; i < fewestRequiredPt; i+=1) {
                prodLotList[i] =
                (Product_Lot__c) TestDataFactory.createSObject(
                    new Product_Lot__c(
                        Product_Name__c = ptList[i].Id,
                        Related_Ticket__c = complaint.Id,
                        Product_Evaluation_Investigation__c = prodEvalList[0].Id,
                        Device_Expiration_Date__c = System.today(),
                        Device_Manufacturing_Date__c = System.today()
                    ),
                    false
                );
            }
            insert prodLotList;

            // Change the Lot # on any Product-Ticket to recalc cumulative fields
            {
                Integer newLen = ptList[0].Batch_Lot_Serial__c.length() - 1;
                ptList[0].Batch_Lot_Serial__c = '#'.repeat(newLen);
                update ptList[0];
            }
            Test.stopTest();

            // Verify that the cumulative fields that overflowed have been handled correctly
            List<CMPL123CME__Investigation__c> invList = [
                SELECT Name, Id, CMPL123_WF_Status__c,
                Product_Lot_Numbers__c,Product_List_Numbers__c,Products__c
                FROM CMPL123CME__Investigation__c
                WHERE CMPL123CME__Complaint__c = :complaint.Id
            ];
            for (CMPL123CME__Investigation__c inv : invList) {
                System.assertEquals(TOO_LONG_LABEL, inv.Products__c, ERROR_TOO_LONG_SCENARIO);
                System.assertEquals(TOO_LONG_LABEL, inv.Product_List_Numbers__c, ERROR_TOO_LONG_SCENARIO);
                System.assertEquals(TOO_LONG_LABEL, inv.Product_Lot_Numbers__c, ERROR_TOO_LONG_SCENARIO);
            }
        }
    }

    /**
     * Neg tests for ticketUpdateAsync such that bad parameters are passed in
     * @author R3.1, Larry
     */
    @isTest
    static void testTicketUpdateAsyncBadParams() {
        Integer numDmlBefore;
        Integer numDmlAfter;

        // Neg test for passing a null parameter
        numDmlBefore = Limits.getDmlStatements();
        try {
            ADDTicketUpdateAsync.ticketUpdateAsync(null, false);
        } catch (Exception ex) {
            Assert.fail(TestUtil.ERROR_NEG +
                'Should NOT crash when passed null');
        }
        numDmlAfter = Limits.getDmlStatements();
        Assert.areEqual(numDmlBefore, numDmlAfter, TestUtil.ERROR_NEG +
            'Should NOT attempt DML when passed null');

        // Neg test for passing an empty collection
        try {
            ADDTicketUpdateAsync.ticketUpdateAsync(new Set<Id>(), false);
        } catch (Exception ex) {
            Assert.fail(TestUtil.ERROR_NEG +
                'Should NOT crash when passed an empty collection');
        }
        numDmlAfter = Limits.getDmlStatements();
        Assert.areEqual(numDmlBefore, numDmlAfter, TestUtil.ERROR_NEG +
            'Should NOT attempt DML when passed an empty collection');
    }
}