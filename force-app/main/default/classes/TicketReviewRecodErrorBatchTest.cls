@isTest
public class TicketReviewRecodErrorBatchTest {
    
    @TestSetup
    private static void setup() {
        
        Group objGroup = new Group(Name = System.label.Ticket_Review_Public_Group, Type='Regular');
        insert objGroup;
        GroupMember GM = new GroupMember();
        GM.GroupId = objGroup.Id;
        GM.UserOrGroupId = userInfo.getUserId();
        insert GM;      
        
    }
    @isTest
    public static void testMethodOne(){
        
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
                                                                                                                    Medical_Assignee_Name__c = userinfo.getuserid(),
                                                                                                                    Quality_Assignee_Name__c =  userinfo.getuserid(),
                                                                                                                    Search_Frequency__c = 'Two Weeks (14 days)',
                                                                                                                    Status__c = 'Active',
                                                                                                                    Division__c = 'ADD'        
                                                                                                                    
                                                                                                                   ),true); 
        
     
        List<Map<String, String>> jsonData = new List<Map<String, String>>
        {
            
            new Map<String, String>{
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
                    'query' => 'SELECT Id FROM ACCOUNT LIMIT 1'
                    }
        };
            
        DynamicTicketReviewSearchSequenceBatch job = new DynamicTicketReviewSearchSequenceBatch(jsonData, 0);
        Id idJob = database.executeBatch(job);
        List<AsyncApexJob> asyncApexObj = [SELECT Id, Status, CreatedById, CompletedDate FROM AsyncApexJob Where  Id = : idJob];
        TicketReviewRecodErrorBatch obj = new TicketReviewRecodErrorBatch();
        TicketReviewRecodErrorBatchSchedular scheduleObj = new TicketReviewRecodErrorBatchSchedular();
        
        Test.startTest();
        
        Ticket_Review__c ticketObj = new Ticket_Review__c();
        ticketObj.Id = ticketReviewObject.Id;
        ticketObj.Pending_Batch_Jobs__c = idJob;
        
        update ticketObj;
        System.schedule('testApexJob','0 0 */2 ? * *', scheduleObj);    
        
        Test.stopTest();  
        Database.executeBatch(obj);
        obj.execute(null, asyncApexObj);
        obj.finish(null);
        
        
        System.assertEquals(1, [SELECT COUNT() FROM CMPL123CME__Investigation__c]);
        System.assertEquals(1, [SELECT COUNT() FROM CMPL123CME__Complaint__c]);
        
    }
    
}