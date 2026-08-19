/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : DynamicTicketReviewSearchControllerTest.
* @Why   : Test class for the DynamicTicketReviewSearchController class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 13-JUL-2020         Code Audit                        Added class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class DynamicTicketReviewSearchControllerTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        Ticket_Review__c review = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(Medical_Assignee_Name__c =userinfo.getuserid(),
                                                                                      Quality_Assignee_Name__c = userinfo.getuserid()),
                true
        );
    }

    /*
    * @Method       : testSearchCriteriaIsEmpty.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testSearchCriteriaIsEmpty() {
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        PageReference reference = controller.fetchQueryResults();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testStatusIsInactive.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testStatusIsInactive() {
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        ticketReview.Status__c = 'Inactive';
        update ticketReview;
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        PageReference reference = controller.fetchQueryResults();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testBatchJobsIsNotEmptyAndCriteriaIsNotNull.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testBatchJobsIsNotEmptyAndCriteriaIsNotNull() {
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        Search__c search = (Search__c) TestDataFactory.createSObject(
                new Search__c(
                        Search_Criteria__c = '{"CMPL123CME__Complaint__c":[{"fieldLabel":"Ticket Receipt Date",' +
                                '"fieldAPIName":"Receipt_Date__c",' +
                                '"datatype":"DATETIME","operator":"greater or equal","operatorSign":">=",' +
                                '"value":"2018-03-27T00:00:00Z","sequenceNumber":"1"},{"fieldLabel":"Ticket Type",' +
                                '"fieldAPIName":"Ticket_Type__c","datatype":"PICKLIST","operator":"equals",' +
                                '"operatorSign":"=","value":"complaint","sequenceNumber":"2"},' +
                                '{"fieldLabel":"Quality Directive Number","fieldAPIName":"Quality_Directive_Number__c",' +
                                '"datatype":"STRING","operator":"contains text","operatorSign":"LIKE","value":"%1013-2018%","sequenceNumber":"3"},' +
                                '{"objectAPIName":"CMPL123CME__Complaint__c","objectLabel":"Ticket","relationshipName":"null",' +
                                '"relatedTicketFieldAPI":"null","logic":"1 AND 2 AND 3"}]}',
                        Criteria__c = '(Ticket: Ticket Receipt Date greater or equal 2019-01-17 AND Product List / Part Number contains in 6C30)',
                        Search_Description__c = 'All complaints since March 27, 2018 with QD 1013-2018.',
                        Ticket_Review__c = ticketReview.Id
                ),
                true
        );
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        PageReference reference = controller.fetchQueryResults();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testBatchJobsIsNotEmptyAndCriteriaIsNotNullAndIsConfirmSearchTrue.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testBatchJobsIsNotEmptyAndCriteriaIsNotNullAndIsConfirmSearchTrue() {
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        Search__c search = (Search__c) TestDataFactory.createSObject(
                new Search__c(
                        Search_Criteria__c = '{"CMPL123CME__Complaint__c":[{"fieldLabel":"Ticket Receipt Date",' +
                                '"fieldAPIName":"Receipt_Date__c",' +
                                '"datatype":"DATETIME","operator":"greater or equal","operatorSign":">=",' +
                                '"value":"2018-03-27T00:00:00Z","sequenceNumber":"1"},{"fieldLabel":"Ticket Type",' +
                                '"fieldAPIName":"Ticket_Type__c","datatype":"PICKLIST","operator":"equals",' +
                                '"operatorSign":"=","value":"complaint","sequenceNumber":"2"},' +
                                '{"fieldLabel":"Quality Directive Number","fieldAPIName":"Quality_Directive_Number__c",' +
                                '"datatype":"STRING","operator":"contains text","operatorSign":"LIKE","value":"%1013-2018%","sequenceNumber":"3"},' +
                                '{"objectAPIName":"CMPL123CME__Complaint__c","objectLabel":"Ticket","relationshipName":"null",' +
                                '"relatedTicketFieldAPI":"null","logic":"1 AND 2 AND 3"}]}',
                        Criteria__c = '(Ticket: Ticket Receipt Date greater or equal 2019-01-17 AND Product List / Part Number contains in 6C30)',
                        Search_Description__c = 'All complaints since March 27, 2018 with QD 1013-2018.',
                        Ticket_Review__c = ticketReview.Id
                ),
                true
        );
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        DynamicTicketReviewSearchController.isConfirmSearch = true;
        PageReference reference = controller.fetchQueryResults();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testBatchJobsIsEmptyAndCriteriaIsNotNullAndAsConfirmSearchTrue.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testBatchJobsIsEmptyAndCriteriaIsNotNullAndAsConfirmSearchTrue() {
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        Search__c search = (Search__c) TestDataFactory.createSObject(
                new Search__c(
                        Search_Criteria__c = '',
                        Criteria__c = 'Test Empty Criteria',
                        Search_Description__c = 'All complaints since March 27, 2018 with QD 1013-2018.',
                        Ticket_Review__c = ticketReview.Id
                ),
                true
        );
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        DynamicTicketReviewSearchController.isConfirmSearch = true;
        DynamicTicketReviewSearchController.childQueriesSet = new Set<String> {'SELECT Id FROM Ticket_Review__c'};
        DynamicTicketReviewSearchController.childObjectAPINameAndQueryMap = new Map<String, String>();
        DynamicTicketReviewSearchController.childObjectAPIAndTicketFieldMap = new Map<String, String>();
        PageReference reference = controller.fetchQueryResults();
        Test.stopTest();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testBatchJobsIsEmptyAndCriteriaIsNotNullAndAsConfirmSearchFalse.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testBatchJobsIsEmptyAndCriteriaIsNotNullAndAsConfirmSearchFalse() {
        Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        Search__c search = (Search__c) TestDataFactory.createSObject(
                new Search__c(
                        Search_Criteria__c = '',
                        Criteria__c = 'Test Empty Criteria',
                        Search_Description__c = 'All complaints since March 27, 2018 with QD 1013-2018.',
                        Ticket_Review__c = ticketReview.Id
                ),
                true
        );
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        DynamicTicketReviewSearchController.isConfirmSearch = false;
        DynamicTicketReviewSearchController.childQueriesSet = new Set<String> {'SELECT Id FROM Ticket_Review__c'};
        DynamicTicketReviewSearchController.childObjectAPINameAndQueryMap = new Map<String, String>();
        DynamicTicketReviewSearchController.childObjectAPIAndTicketFieldMap = new Map<String, String>();
        PageReference reference = controller.fetchQueryResults();
        Test.stopTest();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testBatchJobsIsNotEmpty.
    * @Description  : To test the DynamicTicketReviewSearchController.fetchQueryResults functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testBatchJobsIsNotEmpty() {
        Ticket_Review__c ticketReview = [SELECT Id, (SELECT Id FROM Searches__r) FROM Ticket_Review__c LIMIT 1];
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        PageReference reference = controller.fetchQueryResults();
        System.assertEquals(null, reference);
    }

    /*
    * @Method       : testRecheckBatchCompletion.
    * @Description  : To test the DynamicTicketReviewSearchController.recheckBatchCompletion functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testRecheckBatchCompletion() {
        Ticket_Review__c ticketReview = [SELECT Id, (SELECT Id FROM Searches__r) FROM Ticket_Review__c LIMIT 1];
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        
        PageReference reference = controller.recheckBatchCompletion();
        System.assertEquals(null, reference);
    }
    
    @IsTest
    public static void teststrStoreBatchIdsIsNotBlank() {
           Ticket_Review__c ticketReview = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        Search__c search = (Search__c) TestDataFactory.createSObject(
                new Search__c(
                        Search_Criteria__c = '{"CMPL123CME__Complaint__c":[{"fieldLabel":"Ticket Receipt Date",' +
                                '"fieldAPIName":"Receipt_Date__c",' +
                                '"datatype":"DATETIME","operator":"greater or equal","operatorSign":">=",' +
                                '"value":"2018-03-27T00:00:00Z","sequenceNumber":"1"},{"fieldLabel":"Ticket Type",' +
                                '"fieldAPIName":"Ticket_Type__c","datatype":"PICKLIST","operator":"equals",' +
                                '"operatorSign":"=","value":"complaint","sequenceNumber":"2"},' +
                                '{"fieldLabel":"Quality Directive Number","fieldAPIName":"Quality_Directive_Number__c",' +
                                '"datatype":"STRING","operator":"contains text","operatorSign":"LIKE","value":"%1013-2018%","sequenceNumber":"3"},' +
                                '{"objectAPIName":"CMPL123CME__Complaint__c","objectLabel":"Ticket","relationshipName":"null",' +
                                '"relatedTicketFieldAPI":"null","logic":"1 AND 2 AND 3"}]}',
                        Criteria__c = '(Ticket: Ticket Receipt Date greater or equal 2019-01-17 AND Product List / Part Number contains in 6C30)',
                        Search_Description__c = 'All complaints since March 27, 2018 with QD 1013-2018.',
                        Ticket_Review__c = ticketReview.Id
                ),
                false
        );
         Search__c searchNewObj = (Search__c) TestDataFactory.createSObject(
                new Search__c(
                        Search_Criteria__c = '{"CMPL123CME__TSB__c":[{"fieldLabel":"Ticket Receipt Date",' +
                                '"fieldAPIName":"Receipt_Date__c",' +
                                '"datatype":"DATETIME","operator":"greater or equal","operatorSign":">=",' +
                                '"value":"2018-03-27T00:00:00Z","sequenceNumber":"1"},{"fieldLabel":"Ticket Type",' +
                                '"fieldAPIName":"Ticket_Type__c","datatype":"PICKLIST","operator":"equals",' +
                                '"operatorSign":"=","value":"complaint","sequenceNumber":"2"},' +
                                '{"fieldLabel":"Quality Directive Number","fieldAPIName":"Quality_Directive_Number__c",' +
                                '"datatype":"STRING","operator":"contains text","operatorSign":"LIKE","value":"%1013-2018%","sequenceNumber":"3"},' +
                                '{"objectAPIName":"CMPL123CME__Complaint__c","objectLabel":"Ticket","relationshipName":"null",' +
                                '"relatedTicketFieldAPI":"null","logic":"1 AND 2 AND 3"}]}',
                        Criteria__c = '(Ticket: Ticket Receipt Date greater or equal 2019-01-17 AND Product List / Part Number contains in 6C30)',
                        Search_Description__c = 'All complaints since March 27, 2018 with QD 1013-2018.',
                        Ticket_Review__c = ticketReview.Id
                ),
                false
        );
        List<Search__c> searchList = new List<Search__c>();
        searchList.add(search);
        searchLIst.add(searchNewObj);
        insert searchList;
        ticketReview.Pending_Batch_Jobs__c = '7070j00000OO58tAAD';
        update ticketReview;
        ApexPages.currentPage().getParameters().put('id', ticketReview.Id);
        DynamicTicketReviewSearchController controller = new DynamicTicketReviewSearchController();
        DynamicTicketReviewSearchController.isConfirmSearch = true;
        controller.fetchQueryResults();
        List<String> dataSet = new List<String>{'Test'};
        
        DynamicTicketReviewSearchController.inClausify(dataSet);
        PageReference reference = controller.recheckBatchCompletion();
        
        System.assertEquals(null, reference);
    }
}