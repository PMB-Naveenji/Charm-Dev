/**
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : TranslationEmailHandler.
 * @Why   : Class to Handle Translation Tasks Inbound Emails.
 * @When  : 23-MAR-2017.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID       Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    23-MAR-2017            Work ID / Case ID     Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    04-JUN-2020            Code Audit            Removed 'System.debug()'.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    15-JUN-2020            Code Audit            Removed commented code. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                    09-JUL-2020            Code Audit            Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    04-OCT-2020            Translation Issue     Modified logic related to attachment's body
 *                                                 during Hypercare      composition.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             23-AUG-2022            CHaRM R2.2 #235       Crashfix for when parseCSV tries to update Translation Items
 * with closed parent Translation Tasks. Altered parseCSV. Added parseCsvSaveUpdates, parseCsvExtractEntries, parseCsvDetermineUpdatability,
 * handleInboundEmail. Replaced magic numbers with constants.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             12-JUN-2023            CHaRM R3.1 #116       Changed parseCsvDetermineUpdatability so that Translation Items
 * which are voided will not get updated. This covers the situation where the CSV of translations was sent out, THEN a Customer Response
 * goes to Closed-Voided, thereby voiding Translation Items without the translation vendor being aware.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

global class TranslationEmailHandler implements Messaging.InboundEmailHandler {
    //CSV columns indexes which are used during the process of translation items records population
    //Should be updated if columns count is changed
    @testVisible private static final Integer COLS_COUNT = 7;
    @testVisible private static final Integer INDEX_OF_TRANSLATED_COL = 3;
    @testVisible private static final Integer INDEX_OF_RELATED_ID_COL = 4;
    public Boolean sendEMailToVendor = false;

    /**
     * @Method       : handleInboundEmail.
     * @Description  : It handles Translation Tasks Inbound Email.
     * @Invoke       : From TranslationEmailHandler Class.
     * @Return       : Messaging.InboundEmailResult.
     * @Params       : Messaging.InboundEmail email, Messaging.InboundEnvelope envelope.
     * @Revision     : 25-AUG-2022 Larry: parseCSV for text files now tracks which Translation Tasks are updatable.
     * This information is passed to processWorkflow to stop them from changing Workflow Status
     */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        // Added - W-000172 - try catch block and error email module

        if (email.subject != null && email.subject.startsWithIgnoreCase('Re:')) {
            try{
                if(!email.subject.contains('Translation Required(')){
                    sendEMailToVendor = true;
                    sendErrorMessage(email, Label.Translation_Vendor_has_to_reply_to_the_same_email_with_same_subject ,sendEMailToVendor);
                    return null;
                }

                String logId = email.subject.substringAfter('(').subStringBefore(')');
                if(logId != null && logId != '' && logId.length() != 18){
                    sendEMailToVendor = true;
                    throw new mailCustomException(System.label.Translation_Log_Invalid_Record);
                   // return null;
                }
                Translation_Log__c ttLog = [SELECT Id, Translation_Task_Id__c, Attachment_Details_JSON__c , Type__c
                                            FROM Translation_Log__c
                                            WHERE Id = :logId];
                if (email.textAttachments != null || email.binaryAttachments != null) {
                    if (ttLog.Type__c != 'File') {
                        if (email.textAttachments != null) {
                            for (Messaging.Inboundemail.textAttachment tAttachment : email.textAttachments) {
                                 //Added - W-000172 Custom Exception
                                if(!tAttachment.fileName.endsWithIgnoreCase('.csv') && tAttachment.fileName.contains('.') && !Label.Translation_Task_Skip_File_Type_in_Attachment_Translation.contains(tAttachment.fileName.substringAfterLast('.').toUpperCase())){
                                    sendEMailToVendor = true;
                                    throw new mailCustomException(System.label.Translation_Log_Invalid_File_Extension);
                                }
                                if(tAttachment.fileName.endsWithIgnoreCase('.csv')){
                                    // 25-AUG-2022 Larry: Defined setIncompleteTaskIds
                                    // Read the CSV and update Translation Items.
                                    // Prevent transition to the "Translation Pending Review" status for closed Translation Tasks
                                    Set<Id> setIncompleteTaskIds = parseCSV(tAttachment.body);
                                    processWorkflow(ttLog, setIncompleteTaskIds);
                                }
                            }
                        }
                        if (email.binaryAttachments != null) {
                            for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                                //Added - W-000172 Custom Exception
                                if(!bAttachment.fileName.endsWithIgnoreCase('.csv') && bAttachment.fileName.contains('.') && !Label.Translation_Task_Skip_File_Type_in_Attachment_Translation.contains(bAttachment.fileName.substringAfterLast('.').toUpperCase())){
                                    sendEMailToVendor = true;
                                    throw new mailCustomException(System.label.Translation_Log_Invalid_File_Extension);
                                }
                                if(bAttachment.fileName.endsWithIgnoreCase('.csv')){
                                    // 25-AUG-2022 Larry: Defined setIncompleteTaskIds
                                    // Read the CSV and update Translation Items.
                                    // Prevent transition to the "Translation Pending Review" status for closed Translation Tasks
                                    Set<Id> setIncompleteTaskIds = parseCSV(bAttachment.body.toString());
                                    processWorkflow(ttLog, setIncompleteTaskIds);
                                }
                            }
                        }
                    } else {
                        Set<String> setAttachmentIds = New Set<String>();
                        List<Attachment> attachments = new List<Attachment>();
                        List<String> taskIds = (List<String>)System.JSON.deserialize(ttLog.Translation_Task_Id__c, List<String>.class);
                        Map<String, Object> customAtchIdAndDetailsMap = (Map<String, Object>)JSON.deserializeUntyped(ttLog.Attachment_Details_JSON__c);
                        List<String> attachmentNamesList = new List<String>();
                        for(String customAtchId :  customAtchIdAndDetailsMap.keySet()){
                            Map<String, Object> attachmentDetailsMap = (Map<String, Object>)customAtchIdAndDetailsMap.get(customAtchId);
                            attachmentNamesList.add(customAtchId+'-'+stripExtension(String.valueOf(attachmentDetailsMap.get('standardAttName'))));
                        }

                        if (taskIds != null && taskIds.size() > 0) {
                            Map<String,String> mapTaskAttachmentIds = New Map<String,String>();
                            for(Attachment__c objAttachment : [SELECT Id, Translation_Task__c FROM Attachment__c
                                                                WHERE Translation_Task__c =: taskIds]){
                                mapTaskAttachmentIds.put(objAttachment.Id,objAttachment.Translation_Task__c);
                            }
                            if (email.textAttachments != null) {
                                for (Messaging.Inboundemail.textAttachment tAttachment : email.textAttachments) {
                                    if(attachmentNamesList.contains(stripExtension(tAttachment.fileName))){
                                        attachments.add(
                                            new Attachment(
                                                Name = tAttachment.fileName,
                                                ParentId = mapTaskAttachmentIds.get(tAttachment.fileName.substringBefore('-')),
                                                ContentType = tAttachment.mimeTypeSubType,
                                                Body = Blob.valueOf(tAttachment.Body)
                                            )
                                        );
                                        setAttachmentIds.add(tAttachment.fileName.substringBefore('-'));
                                    }else if(tAttachment.fileName.contains('.') && Label.Translation_Task_Skip_File_Type_in_Attachment_Translation.contains(tAttachment.fileName.substringAfterLast('.').toUpperCase())){
                                      //16APR19 #419 - Skip Image files Processing
                                      //Do Nothing !
                                    }else{
                                        sendEMailToVendor = true;
                                        throw new mailCustomException(System.label.Translation_Log_File_Name_Error);
                                    }
                                }
                            }
                            if(email.binaryAttachments != null) {
                                for(Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                                    if(attachmentNamesList.contains(stripExtension(bAttachment.fileName))){
                                        attachments.add(
                                            new Attachment(
                                                Name = bAttachment.fileName,
                                                ParentId = mapTaskAttachmentIds.get(bAttachment.fileName.substringBefore('-')),
                                                ContentType = bAttachment.mimeTypeSubType,
                                                Body = bAttachment.Body
                                            )
                                        );
                                        setAttachmentIds.add(bAttachment.fileName.substringBefore('-'));
                                    }else if(bAttachment.fileName.contains('.') && Label.Translation_Task_Skip_File_Type_in_Attachment_Translation.contains(bAttachment.fileName.substringAfterLast('.').toUpperCase())){
                                      //16APR19 #419 - Skip Image files Processing
                                      //Do Nothing !
                                    }else{
                                        sendEMailToVendor = true;
                                        throw new mailCustomException(System.label.Translation_Log_File_Name_Error);
                                    }
                                }
                            }
                            if(attachments.size() > 0){
                                Set<String> setTaskIds = (Set<String>)System.JSON.deserialize(ttLog.Translation_Task_Id__c, Set<String>.class);

                                for(Attachment objAttachment : [SELECT Name, ParentId FROM Attachment WHERE ParentId IN: setTaskIds]){
                                   setAttachmentIds.add(objAttachment.Name.substringBefore('-'));
                                }


                                // Prevent Move to "Translation Pending Review" status unless recieved all attachment back from vendor
                                Set<Id> setIncompleteTaskIds = new Set<Id>();
                                for(Translation_Task__c objTranslationTask : [SELECT Id, Email_Attachments__c
                                                                              FROM Translation_Task__c
                                                                              WHERE Id IN: setTaskIds]){
                                    Set<String> setTemp = (Set<String>)System.JSON.deserialize(objTranslationTask.Email_Attachments__c, Set<String>.class);

                                    if(!setAttachmentIds.containsAll(setTemp)){
                                        setIncompleteTaskIds.add(objTranslationTask.Id);
                                    }
                                }
                                processWorkflow(ttLog, setIncompleteTaskIds);
                                insert attachments;
                             }else{
                                //Added - W-000054 Custom Exception
                                sendEMailToVendor = true;
                                throw new mailCustomException(System.label.Translation_Log_Attachment_Error);
                                return null;
                            }
                        }
                    }
                } else if (email.plainTextBody != null && email.plainTextBody.containsIgnoreCase('received')) {
                    String taskId = ttLog.Translation_Task_Id__c;
                    Set<String> taskIds = (Set<String>)System.JSON.deserialize(taskId, Set<String>.class);
                    //Updated - W-000143
                    CMPL123__WF_Step__c wfStep = [
                        SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                        CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                        CMPL123__Start_Status__r.Name = :AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR AND
                        CMPL123__End_Status__r.Name = 'Translation Pending Review' AND
                        CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task'];


                    List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
                    List<Translation_Task__c> updatableTasks = new list<Translation_Task__c>();

                    for(String relatedId : taskIds) {
                        WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(relatedId, wfStep));
                        updatableTasks.add(
                            new Translation_Task__c (
                                CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name,
                                CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name,
                                CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                                CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                                Id = relatedId
                            )
                        );
                    }
                    if(WFHistories.size() > 0 && updatableTasks.size() > 0) {
                        update updatableTasks;
                        insert WFHistories;
                    }

                }else{
                    //Added - W-000054 Custom Exception
                    sendEMailToVendor = true;
                    throw new mailCustomException(System.label.Translation_Log_Attachment_Error);
                    return null;
                }
                return result;
            }catch(Exception E){
                //Added - W-000172 Custom Exception
                sendErrorMessage(email, E.getMessage(),sendEMailToVendor);
                return null;
            }
        }else{
            //Added - W-000172 Custom Exception
            if(email.fromName != 'CHaRM'){
                sendEMailToVendor = true;
                sendErrorMessage(email, Label.Translation_Vendor_has_to_reply_to_the_same_email_with_same_subject ,sendEMailToVendor);
                return null;
            }
        }
        return null;
    }

    /*
    * @Method       : stripExtension.
    * @Description  : It returns attachment's name.
    * @Invoke       : From TranslationEmailHandler Class.
    * @Return       : String.
    * @Params       : String strAttachmentName.
    */
    public static String stripExtension(String strAttachmentName){
        return strAttachmentName != null && strAttachmentName.lastIndexOf('.') > 0
            ? strAttachmentName.substring(0, strAttachmentName.lastIndexOf('.'))
            : strAttachmentName;
    }

    /**
     * @Method       : parseCSV.
     * @Description  : To parse CSV.
     * @Invoke       : From TranslationEmailHandler Class.
     * @Return       : N/A.
     * @Params       : String fileBody.
     * @Revision     : 23-AUG-2022 Larry: Split the record-saving logic into
     * sub-methods to handle defect 235 and decrease this method's complexity.
     * Now returns the Ids of Translation Tasks that are Closed.
     */
    public Set<Id> parseCSV(String fileBody) {
        //Unescape CSV-related transformation and trim body content to remove empty rows
        String fullString = fileBody.unescapeCSV().trim();
        //Needed to iterate through entire file body
        Integer fileBodyLength = fileBody.length();
        //Stores data from csv in usable format
        Map <Integer, List <String>> bodyRowsAndEntities = new Map <Integer, List <String>> ();
        //Indexes for a data map
        Integer currentRowIndex = 0;
        Integer currentColIndex = 0;
        //Flag to indicate that value is encapsulated in quotation mark ("value")
        Boolean isEncapsulatedInQuotationMark = false;
        //Stores value needed to determine if it is the end of encapsulated entity
        Integer countOfQuotationMarksInARow = 0;
        //Flag to indicate that entity is complete and can be added to the list
        Boolean isEndOfEntity = false;
        //Variable to store value of current entity
        String currentEntity = '';
        for (Integer i = 0; i < fileBodyLength; i++) {
            //Get entity part to be processed
            String currentChar = fileBody.mid(i,1);
            //Set encapsulation flag for new entity and add it to current entity
            //or continue processing current entity
            if (String.isBlank(currentEntity)) {
                //Set flag to 'true' if first character of entity is a quotation mark ('"')
                if (currentChar == '"') {
                    isEncapsulatedInQuotationMark = true;
                } else {
                    isEncapsulatedInQuotationMark = false;
                }
                //Add current entity part to current entity
                currentEntity += currentChar;
            } else {
                //Process entity part
                if (isEncapsulatedInQuotationMark) {
                    //Process entity part for encapsulated entity
                    if (currentChar == '"') {
                        countOfQuotationMarksInARow++;
                        currentEntity += currentChar;
                    } else if (Math.mod(countOfQuotationMarksInARow, 2) == 0) {
                        countOfQuotationMarksInARow = 0;
                        currentEntity += currentChar;
                    } else {
                        countOfQuotationMarksInARow = 0;
                        isEndOfEntity = true;
                    }
                } else {
                    //Process entity part for not encapsulated entity
                    if (currentChar == ',' || currentChar == '\n' || i == fileBodyLength - 1) {
                        isEndOfEntity = true;
                    } else {
                        currentEntity += currentChar;
                    }
                }
                //Add entity to the row if entity is complete
                if (isEndOfEntity) {
                    List <String> currentRow;
                    //Figure out is entity should be added to the current row or to the new row
                    if (currentColIndex < COLS_COUNT) {
                        //Entity will be added to the current row
                        if (bodyRowsAndEntities.containsKey(currentRowIndex)) {
                            currentRow = bodyRowsAndEntities.get(currentRowIndex);
                        } else {
                            //Needed for first iteration
                            currentRow = new List <String> ();
                        }
                    } else {
                        //Entity will be added to the new row
                        currentColIndex = 0;
                        currentRowIndex++;
                        currentRow = new List <String> ();
                    }
                    //Trimm and replace dobule quotation marks ("") inside of the entity
                    currentEntity = currentEntity.trim().replace('""', '"');
                    //Replace single quotation mark (") at the beginning
                    //and at the ending of an entity if encapsulated
                    //Flag to indicate was or not beginning and ending quotation marks replaced
                    Boolean quotationReplacementFlag = false;
                    if (isEncapsulatedInQuotationMark) {
                        //Handle case when quotation mark is a value
                        if (currentEntity.length() > 2) {
                            currentEntity = currentEntity.removeStart('"').removeEnd('"');
                        } else {
                            currentEntity = currentEntity.removeStart('"');
                        }
                        //Set quotation replacement flag
                        quotationReplacementFlag = true;
                    }
                    //Check is empty entity leads to current entity
                    if (currentEntity.startsWith(',') && !quotationReplacementFlag) {
                        //Remove comma from current entity
                        currentEntity = currentEntity.removeStart(',');
                        //Add empty entity, because comma indicates that previous entity is empty
                        currentRow.add('');
                        //Increment col index
                        currentColIndex++;
                    }
                    //Add current entity to the row
                    currentRow.add(currentEntity);
                    //Add updated row to the map
                    bodyRowsAndEntities.put(currentRowIndex, currentRow);
                    //Re-set variables related to entity, which was already processed
                    currentEntity = '';
                    isEndOfEntity = false;
                    //Increment col index
                    currentColIndex++;
                }
            }
        }
        // 25-AUG-2022 Larry: Moved extraction and saving logic to sub-methods.
        // Now returns the Ids of Translation Tasks to NOT update
        return parseCsvSaveUpdates(bodyRowsAndEntities).transTaskIdsLocked;
    }

    /**
     * @Description  : Stores Translation Tasks and Translation Items, organized by updatability
     * @Invoke       : From parseCsvSaveUpdates
     * @Author       : Larry Resnik
     * @Date         : 23-AUG-2022
     */
    private class TranslationUpdatabilityWrap {
        // Collections of Translation Tasks that can and cannot be updated respectively
        Set<Id> transTaskIdsCanUpdate;
        Set<Id> transTaskIdsLocked;
        // All updatable Translation Items
        Map<Id, Translation_Item__c> updatableTranslationItemIdToRec;

        public TranslationUpdatabilityWrap() {
            transTaskIdsCanUpdate = new Set<Id>();
            transTaskIdsLocked = new Set<Id>();
            updatableTranslationItemIdToRec = new Map<Id, Translation_Item__c>();
        }
    }

    /**
     * @Description  : Updates Translation Items for parseCSV and determines which Translation Tasks can be updated
     * @Invoke       : From parseCSV
     * @Params       : bodyRowsAndEntities: Each CSV row along with its entries.
     * Each entry is an individual String
     * @Return       : A wrapper class that differentiates both Translation Tasks
     * and Translation Items by whether or not they can be updated
     * @Revision     : 23-AUG-2022 Larry: Moved this logic out of parseCSV.
     * Now does allOrNone=false updates on Translation Items. No longer tries to update
     * Translation Items whose parent Translation Tasks are closed.
     */
    private static TranslationUpdatabilityWrap parseCsvSaveUpdates(
        Map<Integer, List <String>> bodyRowsAndEntities
    ) {
        //Implementation of W-000172 for new logic
        for (Integer key : bodyRowsAndEntities.keySet()) {
            if (bodyRowsAndEntities.get(key).size() != COLS_COUNT) {
                throw new mailCustomException(System.label.Translation_Log_Missing_Column);
            }
        }

        // Extract CSV entries and determine what can be updated in the database
        TranslationUpdatabilityWrap wrap;
        {
            Map<Id, Translation_Item__c> allTranslationItemIdToRec =
                parseCsvExtractEntries(bodyRowsAndEntities);
            // 23-AUG-2022 Larry: Now only updates Translation Items if their
            // parent Translation Task is in a Workflow State that lets them be editable
            wrap = parseCsvDetermineUpdatability(allTranslationItemIdToRec);
        }

        // Apply updates
        List<Translation_Item__c> updatableTransItems = wrap.updatableTranslationItemIdToRec.values();
        if (!updatableTransItems.isEmpty()) {
            Database.update(updatableTransItems, false);
        }
        // Let the caller know what was and was not updatable
        return wrap;
    }

    /**
     * @Description  : Extracts specific data from the parsed CSV
     * @Invoke       : From parseCsvSaveUpdates
     * @Params       : bodyRowsAndEntities: Each CSV row along with its entries.
     * Each entry is an individual String
     * @Return       : A map of Translation Ids to their records.
     * Can be empty, but will not be null
     * @Revision     : 23-AUG-2022 Larry: Moved this logic out of parseCSV.
     * Replaced magic numbers with constants.
     */
    @testVisible
    private static Map<Id, Translation_Item__c> parseCsvExtractEntries(
        Map<Integer, List <String>> bodyRowsAndEntities
    ) {
        //Convert csv data into translation items and update translations (if provided) into the DB
        Map<Id, Translation_Item__c> translationItemIdToRec = new Map<Id, Translation_Item__c>();
        for (Integer key : bodyRowsAndEntities.keySet()) {
            //Ignore headers
            if (key <= 0) {
                continue;
            }
            //Data holders
            Translation_Item__c translationItem = new Translation_Item__c ();
            List <String> currentRow = bodyRowsAndEntities.get(key);
            //Get data and populate translation item or throw an error
            try {
                //Get data
                Id translationItemId = Id.valueOf(currentRow.get(INDEX_OF_RELATED_ID_COL));
                String translatedText = currentRow.get(INDEX_OF_TRANSLATED_COL);
                //Put data into translation item
                translationItem.Id = translationItemId;
                translationItem.Translated__c = translatedText;
                //Put translation item into the list of transaltion items
                translationItemIdToRec.put(translationItemId, translationItem);
            } catch (Exception exc) {
                throw new mailCustomException(System.label.Translation_Log_Invalid_Data);
            }
        }
        return translationItemIdToRec;
    }

    /**
     * @Description  : Updates Translation Items for parseCSV
     * @Invoke       : From parseCsvSaveUpdates
     * @Params       : allTranslationItemIdToRec: Every Translation Item mentioned in the CSV
     * @Return       : See the definition of TranslationUpdatabilityWrap
     * @Author       : Larry Resnik
     * @Date         : 25-AUG-2022
     * @Revision     : R3.1, Larry: No longer fetches voided Translation Items
     */
    private static TranslationUpdatabilityWrap parseCsvDetermineUpdatability(
        Map<Id, Translation_Item__c> allTranslationItemIdToRec
    ) {
        TranslationUpdatabilityWrap wrap = new TranslationUpdatabilityWrap();
        // Determine which of our Translation Items can be updated by whitelisting
        // parent Translation Tasks that are in an editable Workflow Status
        Map<Id, Translation_Item__c> updatableTranslationItemIdToRec =
            new Map<Id, Translation_Item__c>();
        for (Translation_Item__c transItem : [
            SELECT Id, Translation_Task__c, Translation_Task__r.CMPL123_WF_Status__c,
            Is_Voided__c
            FROM Translation_Item__c
            WHERE Id IN :allTranslationItemIdToRec.keySet() AND
            Translation_Task__c != null AND
            Is_Voided__c = false
            WITH SECURITY_ENFORCED
        ]) {
            // Whitelist Translation Tasks and Translation Items by the task's Workflow Status
            Boolean isUpdatable = transItem.Translation_Task__r?.CMPL123_WF_Status__c ==
                AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR;
            if (isUpdatable) {
                wrap.transTaskIdsCanUpdate.add(transItem.Translation_Task__c);
            } else {
                wrap.transTaskIdsLocked.add(transItem.Translation_Task__c);
            }
            // Compose a collection of just the Translation Items that can be updated
            wrap.updatableTranslationItemIdToRec.put(transItem.Id,
                allTranslationItemIdToRec.get(transItem.Id));
        }
        return wrap;
    }

    /*
    * @Method       : processWorkflow.
    * @Description  : It is used to process Workflow actions.
    * @Invoke       : From handleInboundEmail method Class.
    * @Return       : N/A.
    * @Params       : Translation_Log__c ttLog, Set<Id> setIncompleteTaskIds.
    */
    public void processWorkflow(Translation_Log__c ttLog, Set<Id> setIncompleteTaskIds) {
        Set<Id> taskIds = (Set<Id>)System.JSON.deserialize(ttLog.Translation_Task_Id__c, Set<Id>.class);
        if(setIncompleteTaskIds != null && setIncompleteTaskIds.size() > 0){
            taskIds.removeAll(setIncompleteTaskIds);
        }
        //Updated - W-000143
        CMPL123__WF_Step__c wfStep = [
            SELECT Id, CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
            CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
            CMPL123__Start_Status__r.Name = :AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR AND
            CMPL123__End_Status__r.Name = 'Translation Pending Review' AND
            CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task'];


        List<CMPL123__WF_History__c> WFHistories = new list<CMPL123__WF_History__c>();
        List<Translation_Task__c> updatableTasks = new list<Translation_Task__c>();

        for(String relatedId : taskIds) {
            WFHistories.add(ComplaintTriggerHandler.processAutomatedHistoryRecord(relatedId, wfStep));
            updatableTasks.add(
                new Translation_Task__c(
                    CMPL123_WF_Status__c = wfStep.CMPL123__End_Status__r.Name,
                    CMPL123_WF_Action__c = wfStep.CMPL123__Action__r.Name,
                    CMPL123_WF_Action_Performed_On__c = DateTime.now(),
                    CMPL123_WF_Action_Performed_By__c = Userinfo.getUserId(),
                    Id = relatedId
                )
            );
        }
        if(WFHistories.size() > 0 && updatableTasks.size() > 0){
            update updatableTasks;
            insert WFHistories;
        }
    }

    /*
    * @Method       : sendErrorMessage.
    * @Description  : It is used to handle error encountered from email and notify Business Admin. W-000172 - sendErrorMessage.
    * @Invoke       : From handleInboundEmail method Class.
    * @Return       : N/A.
    * @Params       : Messaging.InboundEmail objInboundEmail, String strErrorMessage, Boolean sendEMailToVendor.
    */
    private void sendErrorMessage(Messaging.InboundEmail objInboundEmail, String strErrorMessage,Boolean sendEMailToVendor) {
        Messaging.SingleEmailMessage objSingleEmailMessage = new Messaging.SingleEmailMessage();

        EmailServicesAddress emailAdd = [SELECT EmailDomainName, LocalPart
                                         FROM EmailServicesAddress
                                         WHERE LocalPart = 'translationservice' LIMIT 1];
        String serviceEmail = emailAdd.LocalPart + '@' + emailAdd.EmailDomainName;
        List<String> toAddresses = new List<String>();

        if( objInboundEmail.toAddresses != null ){
            for(String strKey : objInboundEmail.toAddresses){
                if(strKey != serviceEmail){
                    toAddresses.add(strKey);
                }
            }
        }
        if( objInboundEmail.ccAddresses != null ){
            for(String strKey : objInboundEmail.ccAddresses){
                if(strKey != serviceEmail){
                    toAddresses.add(strKey);
                }
         }
        }

        if(toAddresses.size() > 0){
            objSingleEmailMessage.setToAddresses(toAddresses);
        }else {
            objSingleEmailMessage.setTargetObjectId(Userinfo.getUserId());
        }

        List<String> lstmailCCAddresses = new List<String>();
        Set<Id> setBusinessAdminUserIds = new Set<Id>();

        for(Group objGroup  : [SELECT (SELECT userOrGroupId FROM groupMembers) FROM Group WHERE name = 'Business Admin']) {
            for(groupMember objgroupMember : objGroup.groupMembers){
                setBusinessAdminUserIds.add(objgroupMember.userOrGroupId);
            }
        }

        for(User objUser : [SELECT email FROM User WHERE Id IN: setBusinessAdminUserIds]) {
            lstmailCCAddresses.add(objUser.email);
        }

        if(sendEMailToVendor){
            lstmailCCAddresses.add(objInboundEmail.fromAddress);
        }

        objSingleEmailMessage.setCcAddresses(lstmailCCAddresses);

        objSingleEmailMessage.setSubject('Error : '+objInboundEmail.subject );
        objSingleEmailMessage.setSaveAsActivity(false);
        String strError = 'Hello,';
        strError += '\n\n CHaRM encountered error when reading email from vendor ' +objInboundEmail.fromAddress;
        strError += '\n\n Error Message : ' + strErrorMessage;
        strError += '\n\n Thanks';
        strError += '\n CHaRM';
        objSingleEmailMessage.setPlainTextBody(strError);

        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{objSingleEmailMessage});
    }

    //Added - W-000172 Custom Exception
    public class mailCustomException extends Exception{}
}