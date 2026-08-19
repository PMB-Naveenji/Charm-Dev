/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : DynamicTicketReviewSearchSequenceTest.
* @Why   : Test class for the DynamicTicketReviewSearchSequenceBatch class.
* @When  : 07-JUN-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 07-JUN-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 13-JUL-2020         Code Audit                        Added class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*Juneid                02-Aug-2021           MIR Devlopment                   Update Class for Cover MIR Logic
* --------------------------------------------------------------------------------------------------------------------------------------
*Dinesh Kumar          20-Sep-2024           CHaRM-R5/IPDR 191                Updated dynamicTicketReviewbatchTest method
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest private class DynamicTicketReviewSearchSequenceTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */

    @TestSetup
    private static void setup() {
       String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'INDIA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Void',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMPL123CME__CMPL123_WF_Action__c = 'Void',
                        Overall_Reportable_Status__c = 'Reportable',
                        Is_Product_Evaluation_Investigation_chil__c = true,
                        Med_Evaluator_Pending_MDCs__c = false),
                true
        );
        insert new CMPL123CME__Investigation__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened',
                        CMPL123_WF_Action_Performed_On__c = System.today());
        

        
        Ticket_Review__c ticketReviewObject = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(FA_CAPA_Short_Description__c = 'test123',
                                                                                    Medical_Assignee_Name__c =userinfo.getuserid(),
                                                                                      Quality_Assignee_Name__c = userinfo.getuserid(),
                                                                                       Search_Frequency__c = 'Two Weeks (14 days)',
                                                                                         Status__c = 'Active',
                                                                                          Division__c = 'ADD'        
                                                                                                 
                                                       ),true);  
    }

    /*
    * @Method       : dynamicTicketReviewbatchTest.
    * @Description  : To test the DynamicTicketReviewSearchSequenceBatch functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest private static void dynamicTicketReviewbatchTest() {
      DateTime startDate;//CHaRM-R5
      DateTime endDate;//CHaRM-R5
       DateTime daterangeStart;
        daterangeStart = DateTime.newInstance(2022, 5, 4, 19, 37, 55);
       Ticket_Review__c ticketReviewObject = [SELECT Id, FA_CAPA_Short_Description__c, Medical_Assignee_Name__r.Name, Medical_Assignee_Name__c, Quality_Assignee_Name__c, Search_Frequency__c, Status__c, Division__c,Search_Status__c FROM Ticket_Review__c limit 1];
       //CHaRM-R5: To check the field 'Search Status' is getting populated with 'None' Status when the Batch is not started.
        System.assertEquals('None', ticketReviewObject.Search_Status__c);
       CHaRM_Misc_Settings__c dateRange = new CHaRM_Misc_Settings__c();
        dateRange.TicketReviewSearchRange__c= 3;
            insert dateRange;
        //CHaRM R5: added the start and end date values to handle in the batch
         startDate = DateTime.newInstance(2022, 5, 4, 19, 37, 55);
        endDate = DateTime.newInstance(2022, 8, 4, 19, 37, 55);
        List<Map<String, String>> jsonData = new List<Map<String, String>>{
                new Map<String, String>{
                        'isParent' => 'TRUE',
                        'objectsIncludedInSearchSet' => JSON.serialize(new Set<String>{
                                CMPL123CME__Complaint__c.class.getName()
                        }),
                        'childObjectAPIAndTicketFieldMap' => '{"CMPL123CME__EMDR__c":"CMPL123CME__Complaint__c","TSB__c":"Ticket__c"}',
                        'childObjectAPINameAndQueryMap' => '{"CMPL123CME__EMDR__c":"SELECT Id,RecordType.Name,CMPL123CME__CMPL123_WF_Status__c,Classification__c,CMPL123CME__Complaint__c FROM CMPL123CME__EMDR__c WHERE CMPL123CME__CMPL123_WF_Status__c LIKE \'%Open%\' LIMIT 2000","TSB__c":"SELECT Id,Name,TSB_Description__c,TSB_Type__c,Ticket__c FROM TSB__c WHERE CreatedDate <= 2021-07-13T00:00:00Z LIMIT 2000"}',
                        'childObjQuery' => JSON.serialize(new Set<String> {
                                'Select CMPL123CME__Complaint__c, CMPL123_WF_Status__c, ' +
                                        'CMPL123_WF_Action_Performed_On__c ' +
                                'FROM CMPL123CME__Investigation__c'}),
                        'searchingChildObjectsSet' => '[]',
                            'ticketReviewId' => ticketReviewObject.Id,
                        'query' => 'SELECT Id FROM ACCOUNT'
                }
        };
        DynamicTicketReviewSearchSequenceBatch job = new DynamicTicketReviewSearchSequenceBatch(jsonData, 0);
        job.start(null);
        job.execute(null, new List<Account>());
        
        Test.startTest();
        jsonData.get(0).put('isParent', 'FALSE');
        jsonData.get(0).put('childObjectAPIAndTicketFieldMap', JSON.serialize(new Map<String, String> {
                'CMPL123CME__Investigation__c' => 'CMPL123CME__Complaint__c'
        }));
        job = new DynamicTicketReviewSearchSequenceBatch(jsonData, 0);
          Boolean dmlExceptionCaught = false;
        try {
            job.execute(null, new List<CMPL123CME__Complaint__c>{
                    new CMPL123CME__Complaint__c()
            });
        } catch (System.DmlException ex) {
            dmlExceptionCaught = true;
        }
        jsonData.add(new Map<String, String>{
                'isParent' => 'FALSE',
                'objectsIncludedInSearchSet' => JSON.serialize(new Set<String>{
                        CMPL123CME__Complaint__c.class.getName()
                }),
               'childObjectAPIAndTicketFieldMap' => '{"CMPL123CME__EMDR__c":"CMPL123CME__Complaint__c"}',
                'childObjectAPINameAndQueryMap' => '{"CMPL123CME__EMDR__c":"SELECT Id,RecordType.Name,CMPL123CME__CMPL123_WF_Status__c,Classification__c,CMPL123CME__Complaint__c FROM CMPL123CME__EMDR__c WHERE CMPL123CME__CMPL123_WF_Status__c LIKE \'%Open%\' LIMIT 2000"}',

                'childObjQuery' => JSON.serialize(new Set<String> {
                                'Select CMPL123CME__Complaint__c, CMPL123_WF_Status__c, ' +
                                        'CMPL123_WF_Action_Performed_On__c ' +
                                'FROM CMPL123CME__Investigation__c'}),
                'searchingChildObjectsSet' => '[]',
                  'ticketReviewId' => ticketReviewObject.Id,
                       'query' => 'SELECT Id FROM ACCOUNT'
        });
        //CHaRM-R5: To check the field 'Search Status' is getting populated with 'In Progress' Status when the Batch is in progress status
         Ticket_Review__c ticketReviewObject1 = [SELECT Id, FA_CAPA_Short_Description__c,Search_Status__c FROM Ticket_Review__c where FA_CAPA_Short_Description__c='test123' limit 1];
        System.assertEquals('In Progress', ticketReviewObject1.Search_Status__c);
        
        Boolean caughtException = false;
        job = new DynamicTicketReviewSearchSequenceBatch(jsonData, 0);
        try {
            job.finish(null);
        } catch (Exception ex) {
            caughtException = true;
        }
        Test.stopTest();
        //CHaRM-R5: To check the field 'Search Status' is getting populated with 'Completed' Status when the Batch is Completed sucessfully.
        Ticket_Review__c ticketReviewObject2 = [SELECT Id, FA_CAPA_Short_Description__c,Search_Status__c FROM Ticket_Review__c where FA_CAPA_Short_Description__c='test123' limit 1];
        System.assertEquals('Completed', ticketReviewObject2.Search_Status__c);
        System.assert(!caughtException);
       System.assert(!dmlExceptionCaught);
       System.assertEquals(1, [SELECT COUNT() FROM CMPL123CME__Investigation__c]);
       System.assertEquals(1, [SELECT COUNT() FROM CMPL123CME__Complaint__c]);
       new DynamicTicketReviewSearchSequenceBatch(jsonData,0, DateTime.newInstance(2022, 5, 4, 19, 37, 55));
        system.debug('jsonData'+new DynamicTicketReviewSearchSequenceBatch(jsonData,0, DateTime.newInstance(2022, 5, 4, 19, 37, 55)));
      
    }
}