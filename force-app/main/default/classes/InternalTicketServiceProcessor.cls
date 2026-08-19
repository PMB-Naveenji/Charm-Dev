/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : InternalTicketServiceProcessor.
* @Why   : This web service class process the ticket data(receiving data from TicketServiceHandler) and will upsert data.
* @When  : 23-MAR-2017.
* @Where : From TicketServiceHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    18-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@RestResource(urlMapping='/ASPEN/v1.0/*')
global class InternalTicketServiceProcessor {
    public static boolean preStatusChangeFlag = false;      // 08MAR19 - DEF#354 fix
    public static boolean newTicketFlag = false;            // 18MAR19 - DEF#354 - Change Request	
    public static Boolean preventMDCGenerationFlag = false;
   // public static Boolean preventMDCGenerationFlag = false; // Added for 409 - Anup
    /*
    * @Method       : insertChildRecords.
    * @Description  : Handles all the ticket data received from cmsnext(TicketServiceHandler) and insert into the respective object.
    * @Invoke       : Post operations on '/ASPEN/v1.0/*' endpoint.
    * @Return       : ResponseWrapper.
    * @Params       : N/A.
    */
    @HttpPost
    global static ResponseWrapper insertChildRecords() {
        TicketUtil.addTrace('InternalTicketServiceProcessor.insertChildRecords');
        ResponseWrapper response = new ResponseWrapper();

        RestRequest req = RestContext.request;
        String dataType = RestContext.request.params.get('type');
        System.debug('req.requestBody--->' + req.requestBody.toString());

        if(dataType == 'parent') {
            Map<String,SObject> childRecordMap = (Map<String,SObject>)JSON.deserialize(req.requestBody.toString(), Map<String,SObject>.class);
            Account acc = (Account)childRecordMap.get('ACCOUNT');

            CMPL123CME__Complaint__c ticket = (CMPL123CME__Complaint__c)childRecordMap.get('TICKET');                       
            
            // 26MAR19 - Updated for Def#457 Fix
            pRE_Information__c preInfo = new pRE_Information__c();
            if(childRecordMap.containsKey('PREINFO')) {
                preInfo = (pRE_Information__c)childRecordMap.get('PREINFO');
            } else {
                preInfo = null;
            }

            Savepoint sp = Database.setSavepoint();
            String objName = '';
            try {
                response.successMap = new Map<String,String>();
                objName = 'Account';
                UPSERT acc Customer_External_Id__c;
                ticket.CMPL123CME__Customer__c = acc.Id;

                objName = 'Complaint';
                UPSERT ticket CMSNext_Ticket_Id__c;

                // 26MAR19 - Updated the logic for DEF#457 fix
                if(preInfo != null) {
                    preInfo.Complaint__c = ticket.Id;
                    objName = 'pRE Information';
                    UPSERT preInfo External_Id__c;
                    response.successMap.put('preInfoId', preInfo.Id);
                } else {
                    response.successMap.put('preInfoId', null);
                }

                response.isSuccess = TRUE;
                response.successMap.put('accId', acc.Id);
                response.successMap.put('ticketId', ticket.Id);

                // 09FEB19 - Added for better debugging the issue
                dataType = ticket.CMSNext_Ticket_Number__c;
            } catch(DMLException de) {
                Database.rollBack(sp);
                response.isSuccess = FALSE;
                response.errors = new List<Error>();
                response.errors.add(new Error(de.getDmlMessage(0), String.valueOf(de.getDmlIndex(0)), String.valueOf(de.getDmlType(0)), objName + ' (Parent)'));
            }
        } else {
            Map<String,List<SObject>> ticketChildRecordMap = (Map<String,List<SObject>>)JSON.deserialize(req.requestBody.toString(), Map<String,List<SObject>>.class);
            Savepoint savep = Database.setSavepoint();
            String objLabel = '';                         
			
            try {
                for(String objectName : ticketChildRecordMap.keySet()){
                    String objName = objectName.subStringBefore('~');
                    // 08MAR19 - DEF#354
                    // 18MAR19 - DEF#354 - Change Request
                    if(dataType == 'newTicket') {
                        newTicketFlag = true;
                    } else if(objName == 'pRE_Question__c' && dataType == 'preFlag') {
                        preStatusChangeFlag = true;
                    }
                    
                    DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objName).getDescribe();
                    Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
                    objLabel = describe.getLabel();

                    Schema.SObjectField field = fieldMap.get(objectName.subStringAfter('~'));

                    List<sObject> upsertRecordList = new List<sObject>();
                    upsertRecordList = dynamicUpsert(ticketChildRecordMap.get(objectName), objName);                    
                    dataType = objName;
                    if(upsertRecordList != null && upsertRecordList.size() > 0 ){                        
                        Database.upsert(upsertRecordList, field);                                                
                        response.isSuccess = TRUE;
                    }
                }
            } catch(Exception e) {
                Database.rollBack(savep);
                response.isSuccess = FALSE;
                response.errors = new List<Error>();
                response.errors.add(new Error(e.getMessage(), e.getLineNumber() +' : '+ e.getTypeName(), e.getTypeName(), objLabel + ' (Child)'));
            }
        }

        return response;
    }
    
    global class ResponseWrapper{
        public Boolean isSuccess = true;
        public Map<String,String> successMap;
        public List<Error> errors;
    }

    global class Error{
        public String errorMessage;
        public String errorCode;
        public String errorType;
        public String errorTxn;

        public Error(String errorMessage, String errorCode, String errorType){
            this.errorMessage = errorMessage;
            this.errorCode = errorCode;
            this.errorType = errorType;
        }

        public Error(String errorMessage, String errorCode, String errorType, String errorTxn){
            this.errorMessage = errorMessage;
            this.errorCode = errorCode;
            this.errorType = errorType;
            this.errorTxn = errorTxn + ' processing failed';
        }
    }

    /*
    * @Method       : dynamicUpsert.
    * @Description  : This method typeCast the sObject in the respective object.
    * @Invoke       : From insertChildRecords method.
    * @Return       : List<sObject>.
    * @Params       : List<SObject> records, String objName.
    */
    public static List<sObject> dynamicUpsert(List<SObject> records,String objName){
        if(records.size() > 0){
            TicketUtil.addTrace('InternalTicketServiceProcessor.dynamicUpsert');
            Schema.SObjectType sObjectType = records.getSObjectType();
            List<SObject> castRecords =  new List<SObject>();
            if (objName != null){
                String listType = 'List<' + objName + '>';
                castRecords = (List<SObject>)Type.forName(listType).newInstance();
                castRecords.addAll(records);
            }
            return castRecords;
        }
        return null;
    }
}