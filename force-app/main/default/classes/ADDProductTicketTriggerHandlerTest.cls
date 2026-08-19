/**
 * @why  : Test class for the ADDProductTicketTriggerHandler.
 * @when : 28-DEC-2020.
 * @what : Class to handle different scenarios from ADDProductTicketTriggerHandler.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                    Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                 28-DEC-2020             TWD Upgrade issue               Created. Added 'executeLogicFromWFRulesTest()' method
 *                                                                                   to test moved logic from Workflow Rules with
 *                                                                                   Field Updates on Product-Ticket to Apex.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          14-SEP-2022             CHaRM R2.2 IPDR 66              Increased coverage for new methods
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          06-OCT-2022             CHaRM R2.2 IPDR 66              Added makeTicket, makeProduct, makeData,
 * getNumProdEvalsToOverflowCumul, testFixProdEvalFieldsAbbreviation. Now tests that cumulative ProdEval strings are handled
 * correctly when filled with more characters than the field length allows. Simplified executeLogicFromWFRulesTest
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          06-JUL-2023             CHaRM R3.1                      Moved makeProduct to TestDataFactory under the name
 * makeProductWithLongNames. Minor code changes to share functionality with ADDTicketUpdateAsyncTest
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
public class ADDProductTicketTriggerHandlerTest {
    private static final String PROFILE_COMMON = AspenConstants.PROFILE_STD;
    private static final String PROFILE_EXTERNAL = 'ASPEN Integration';
    private static final String EMAIL_INTERNAL = 'intern@test.com';
    private static final String EMAIL_EXTERNAL = 'extern@test.com';

    private static final Map<String, SObjectField> PRODUCT_FIELDS =
        SObjectType.CMPL123__Product__c.fields.getMap();
    private static Integer nameLen {
        get{ return PRODUCT_FIELDS.get('Name').getDescribe().getLength(); }
    }
    private static Integer lotNumLen {
        get{ return PRODUCT_FIELDS.get('CMPL123__Lot_No__c').getDescribe().getLength(); }
    }
    private static Integer listNumLen {
        get{ return PRODUCT_FIELDS.get('List_Number__c').getDescribe().getLength(); }
    }

    /**
     * Factory method that makes Tickets
     * @author 06-OCT-2022 Larry Resnik
     */
    private static CMPL123CME__Complaint__c makeTicket(Boolean alsoInsert) {
        Id rtId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        String rand = String.valueOf((Math.random() * 100000.0).intValue()).leftPad(6, '0');
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = rtId,
                Division__c  = AspenConstants.DIVISION_DIAGNOSTICS,
                pRE_Status__c  = AspenConstants.STR_Yes,
                Business_Unit__c  = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                Country_of_origin__c = 'USA',
                CMSNext_Ticket_Number__c = '0600560C' + rand,
                Trending_issue_Bucket__c = 'ACON'
            ),
            alsoInsert
        );
        return complaint;
    }

    @TestSetup
    static void makeData() {
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(
            new ADD_App_Settings__c(), true);

        final Set<String> ALL_PROFILES = new Set<String>{
            PROFILE_COMMON, PROFILE_EXTERNAL
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
    }

    /**
     * Determine how many Product-Tickets to create so all cumulative fields overflow
     * @author 06-OCT-2022 Larry Resnik
     * @revision R3.1, Larry: Made public so that ADDTicketUpdateAsyncTest can use it
     */
    public static Integer getNumProdEvalsToOverflowCumul() {
        // Get field lengths of Product-Ticket fields
        final Map<String, SObjectField> PT_FIELDS =
            SObjectType.Product_Ticket__c.fields.getMap();
        Integer ptNameLen = PT_FIELDS.get('Product_Name__c').getDescribe().getLength();
        Integer ptLotNumLen = PT_FIELDS.get('Batch_Lot_Serial__c').getDescribe().getLength();
        Integer ptListNumLen = PT_FIELDS.get('Product_List_Number__c').getDescribe().getLength();
        // Get field lengths of Product fields
        Integer productNameLen = PRODUCT_FIELDS.get('Name').getDescribe().getLength();
        Integer productLotNumLen = PRODUCT_FIELDS.get('CMPL123__Lot_No__c').getDescribe().getLength();
        Integer productListNumLen = PRODUCT_FIELDS.get('List_Number__c').getDescribe().getLength();

        // Product fields are copied into Product-Tickets. Determine whether source
        // or destination field is shorter
        Integer shortestName = Math.min(ptNameLen, productNameLen);
        Integer shortestListNum = Math.min(ptLotNumLen, productLotNumLen);
        Integer shortestLotNum = Math.min(ptListNumLen, productListNumLen);
        System.debug(String.format(
            'shortestName: {0}, shortestListNum: {1}, shortestLotNum: {2}',
            new Object[]{shortestName, shortestListNum, shortestLotNum}));

        // Calculate how many names, list #s, or lot #s it takes to fill up each cumulative field
        Double namesToFill = (Double)
            ADDProductTicketTriggerHandler.prodEvalCumulNamesLen / shortestName;
        Double listNumsToFill = (Double)
            ADDProductTicketTriggerHandler.prodEvalCumulListNumsLen / shortestListNum;
        Double lotNumsToFill = (Double)
            ADDProductTicketTriggerHandler.prodEvalCumulLotNumsLen / shortestLotNum;
        System.debug(String.format(
            'namesToFill: {0}, listNumsToFill: {1}, lotNumsToFill: {2}',
            new Object[]{namesToFill, listNumsToFill, lotNumsToFill}));
        // If the names, list #s, or lot #s fit PERFECTLY into the cumulative field,
        // then you need ONE MORE character (implies one more record) to OVERFLOW the field
        if (Math.abs(namesToFill - namesToFill.intValue()) <= 0.00001) {
            namesToFill += 1.0;
        }
        if (Math.abs(listNumsToFill - listNumsToFill.intValue()) <= 0.00001) {
            listNumsToFill += 1.0;
        }
        if (Math.abs(lotNumsToFill - lotNumsToFill.intValue()) <= 0.00001) {
            lotNumsToFill += 1.0;
        }

        // Round UP to count how many RECORDS we need
        Integer numCumulNamesToOverflow = Math.ceil(namesToFill).intValue();
        Integer numCumulListNumsToOverflow = Math.ceil(listNumsToFill).intValue();
        Integer numCumulLotNumsToOverflow = Math.ceil(lotNumsToFill).intValue();
        System.debug(String.format(
            'numCumulNamesToOverflow: {0}, numCumulListNumsToOverflow: {1}, numCumulLotNumsToOverflow: {2}',
            new Object[]{numCumulNamesToOverflow, numCumulListNumsToOverflow, numCumulLotNumsToOverflow}));

        // What are the fewest number of Product-Tickets needed to overflow ALL cumulative field?
        // Note: As of 06-OCT-2022, this value is calculated to be FOUR.
        // Provable because 255 chars on ProdEval.ProductNames is overflowed with 4 Products
        // whose Names are 80 chars each. (80*3 is 240) < 255 < (80*4 = 320)
        Integer fewestRequiredPt = Math.max(
            Math.max(numCumulNamesToOverflow, numCumulListNumsToOverflow),
            numCumulLotNumsToOverflow);

        System.assert(fewestRequiredPt > 0,
            'Tester bug: Should make at least one Product-Ticket. Bad math? Got ' + fewestRequiredPt);
        System.assert(fewestRequiredPt < 50,
            'Tester bug: Need to make unreasonable number of Product-Tickets. Bad math? Got ' + fewestRequiredPt);
        return fewestRequiredPt;
    }

    /**
     * Pos/neg tests for fixProdEvalFields where cumulative fields are too long
     * @author 06-OCT-2022 Larry Resnik
     */
    @isTest
    static void testFixProdEvalFieldsAbbreviation() {
        Integer fewestRequiredPt = getNumProdEvalsToOverflowCumul();

        User usr = [SELECT Id FROM User WHERE Email = :EMAIL_INTERNAL LIMIT 1];
        System.runAs(usr) {
            Test.startTest();
            // Create a Complaint to contain one ProdEval and many Product-Tickets
            CMPL123CME__Complaint__c complaint = makeTicket(true);

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
                System.assertEquals(System.label.CumulativeFieldTooLong,
                    inv.Products__c, 'Long cumulative field was not replaced with a warning');
                System.assertEquals(System.label.CumulativeFieldTooLong,
                    inv.Product_List_Numbers__c, 'Long cumulative field was not replaced with a warning');
                System.assertEquals(System.label.CumulativeFieldTooLong,
                    inv.Product_Lot_Numbers__c, 'Long cumulative field was not replaced with a warning');
            }
        }
    }

    @IsTest
    static void executeLogicFromWFRulesTest() {
        // 06-OCT-2022 Larry Resnik: Moved complaint, product, and user creation to factories
        CMPL123CME__Complaint__c complaint = makeTicket(true);
        CMPL123__Product__c product = null;
        User usr = [SELECT Id FROM User WHERE Email = :EMAIL_EXTERNAL LIMIT 1];
        System.runAs(usr) {
            product = TestDataFactory.makeProductWithLongNames(true);
        }

        Test.startTest();

        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
            Event_Ticket__c = complaint.Id,
            Likely_Cause__c = 'Yes',
            Product__c = product.Id
        ), true);

        //14-SEP-2022 Larry added below line to cover Trigger Update Scenarios
        update prodTicket;

        Product_Ticket__c newPT = [SELECT Product_List_Number_Text__c, List_Base_Trending_Issue_Bucket__c, Registration_Number__c, Bactch_Likely_List__c,
                                        Product_Name__c, Product_List_Number__c, Batch_Lot_Serial__c, Likely_Cause__c
                                    FROM Product_Ticket__c
                                    WHERE Id = :prodTicket.Id];

        System.assertEquals(product.List_Number__c, newPT.Product_List_Number_Text__c);
        System.assertEquals(product.List_Base__c + '/' + complaint.Trending_issue_Bucket__c, newPT.List_Base_Trending_Issue_Bucket__c);
        System.assertEquals(complaint.CMSNext_Ticket_Number__c + '(' + 'Complaint' + ')', newPT.Registration_Number__c);
        System.assertEquals(
            newPT.Product_Name__c + ' - -' + newPT.Product_List_Number__c + ' - ' + newPT.Batch_Lot_Serial__c + '\n'
                + 'Likely Cause: ' + newPT.Likely_Cause__c,
            newPT.Bactch_Likely_List__c
        );

        Test.stopTest();
    }
}