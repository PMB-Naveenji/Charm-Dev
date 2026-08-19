/**
 * This class is created for update of parent records field with concatenated data from all children.
 *
 * Created by odemi on 2019-07-04.
 */

public inherited sharing class ReportsRelatedDataUtil {
    private static final String QUERY_FORMAT = 'SELECT {0} FROM {1} WHERE {2} IN :parentIds {3}';
    private static final Integer FIELD_LENGTH_LIMIT = 131071;

    private static final String newValue = 'new';
    private static final String oldValue = 'old';
    private enum Operation {InsertOp, UpdateOp, DeleteOp}

    private ContextConfiguration context;
    private List<Id> parentIds;

    @TestVisible
    private ReportsRelatedDataUtil(ContextConfiguration config) {
        context = config;
    }

    public static void updateComplaintWithRegisteredSiteNames(List<SObject> oldRecords, List<SObject> newRecords) {
        Map<SObjectField, SObjectField> mapping = new Map<SObjectField, SObjectField>{
                Product_Ticket__c.Registered_Site_Name__c => CMPL123CME__Complaint__c.Manufacturing_Site__c
        };
        ReportsRelatedDataUtil.ContextConfiguration contextConfiguration = new ReportsRelatedDataUtil.ContextConfiguration()
                .setChildType(Product_Ticket__c.SObjectType)
                .setParentType(CMPL123CME__Complaint__c.SObjectType)
                .setParentFieldMarker(Product_Ticket__c.Event_Ticket__c)
                .setDataMapping(mapping);
        Map<String, List<SObject>> filteredRecords = filterJunkRecords(
                oldRecords,
                newRecords,
                mapping.keySet(),
                contextConfiguration.getParentFieldMarker()
        );
        List<Id> parentRecordsIds = trackParents(
                filteredRecords.get(oldValue),
                filteredRecords.get(newValue),
                contextConfiguration.getParentFieldMarker()
        );

        new ReportsRelatedDataUtil(contextConfiguration)
                .configureParentsForUpdate(parentRecordsIds)
                .updateParentFields();
    }

    public static void updateComplaintWithTicketNotesData(List<SObject> oldRecords, List<SObject> newRecords) {
        Map<SObjectField, SObjectField> mapping = new Map<SObjectField, SObjectField>{
                Ticket_Note__c.Ticket_Notes_Native__c => CMPL123CME__Complaint__c.Ticket_Notes_Native__c,
                Ticket_Note__c.Ticket_Notes_Translated__c => CMPL123CME__Complaint__c.Ticket_Notes_Translated__c
        };
        ReportsRelatedDataUtil.ContextConfiguration contextConfiguration = new ReportsRelatedDataUtil.ContextConfiguration()
                .setChildType(Ticket_Note__c.SObjectType)
                .setParentType(CMPL123CME__Complaint__c.SObjectType)
                .setParentFieldMarker(Ticket_Note__c.Ticket__c)
                .setCheckFieldLengthLimitation(true)
                .setDataMapping(mapping);
        Map<String, List<SObject>> filteredRecords = filterJunkRecords(
                oldRecords,
                newRecords,
                mapping.keySet(),
                contextConfiguration.getParentFieldMarker()
        );
        List<Id> parentRecordsIds = trackParents(
                filteredRecords.get(oldValue),
                filteredRecords.get(newValue),
                contextConfiguration.getParentFieldMarker()
        );

        new ReportsRelatedDataUtil(contextConfiguration)
                .configureParentsForUpdate(parentRecordsIds)
                .updateParentFields();
    }

    public static void updatePMRAWithRiskAssessmentsData(List<SObject> oldRecords, List<SObject> newRecords) {
        Map<SObjectField, SObjectField> mapping = new Map<SObjectField, SObjectField>{
                Risk_Assessment__c.Product_Name__c => Post_Market_Risk_Assessment_Risk_Contr__c.Related_Product_List_Product_Name__c,
                Risk_Assessment__c.Product_List_Number__c => Post_Market_Risk_Assessment_Risk_Contr__c.Product_List_Number__c
        };
        ReportsRelatedDataUtil.ContextConfiguration contextConfiguration = new ReportsRelatedDataUtil.ContextConfiguration()
                .setChildType(Risk_Assessment__c.SObjectType)
                .setParentType(Post_Market_Risk_Assessment_Risk_Contr__c.SObjectType)
                .setParentFieldMarker(Risk_Assessment__c.Post_Market_Risk_Asst_Risk_Ctrl__c)
                .setIsClonedParentMarker(Post_Market_Risk_Assessment_Risk_Contr__c.Is_Cloned__c)
                .setDataMapping(mapping);
        Map<String, List<SObject>> filteredRecords = filterJunkRecords(
                oldRecords,
                newRecords,
                mapping.keySet(),
                contextConfiguration.getParentFieldMarker()
        );
        List<Id> parentRecordsIds = trackParents(
                filteredRecords.get(oldValue),
                filteredRecords.get(newValue),
                contextConfiguration.getParentFieldMarker()
        );

        new ReportsRelatedDataUtil(contextConfiguration)
                .configureParentsForUpdate(parentRecordsIds)
                .updateParentFields();
    }

    public static void updateEmdrWithConcomitantProductsData(List<SObject> oldRecords, List<SObject> newRecords) {
        Map<SObjectField, SObjectField> mapping = new Map<SObjectField, SObjectField>{
                CMPL123CME__Concomitant_Product__c.CMPL123CME__D11_Product__c => CMPL123CME__EMDR__c.Concomitant_Products_D11__c
        };
        ReportsRelatedDataUtil.ContextConfiguration contextConfiguration = new ReportsRelatedDataUtil.ContextConfiguration()
                .setChildType(CMPL123CME__Concomitant_Product__c.SObjectType)
                .setParentType(CMPL123CME__EMDR__c.SObjectType)
                .setParentFieldMarker(CMPL123CME__Concomitant_Product__c.CMPL123CME__Related_EMDR__c)
                .setDataMapping(mapping);
        Map<String, List<SObject>> filteredRecords = filterJunkRecords(
                oldRecords,
                newRecords,
                mapping.keySet(),
                contextConfiguration.getParentFieldMarker()
        );
        List<Id> parentRecordsIds = trackParents(
                filteredRecords.get(oldValue),
                filteredRecords.get(newValue),
                contextConfiguration.getParentFieldMarker()
        );

        new ReportsRelatedDataUtil(contextConfiguration)
                .configureParentsForUpdate(parentRecordsIds)
                .updateParentFields();
    }

    public static void updateComplaintWithInvestigationsData(List<SObject> oldRecords, List<SObject> newRecords) {
        Map<SObjectField, SObjectField> mapping = new Map<SObjectField, SObjectField>{
                CMPL123CME__Investigation__c.CAPA_Reference__c => CMPL123CME__Complaint__c.CAPA_Reference__c,
                CMPL123CME__Investigation__c.Is_Investigation_Required__c => CMPL123CME__Complaint__c.Is_Investigation_Required__c
        };
        ReportsRelatedDataUtil.ContextConfiguration contextConfiguration = new ReportsRelatedDataUtil.ContextConfiguration()
                .setChildType(CMPL123CME__Investigation__c.SObjectType)
                .setParentType(CMPL123CME__Complaint__c.SObjectType)
                .setParentFieldMarker(CMPL123CME__Investigation__c.CMPL123CME__Complaint__c)
                .setChildFieldMarker('PE')
                .setFieldsToPopulateWithMarker(new List<SObjectField>{
                        CMPL123CME__Investigation__c.CAPA_Reference__c
                })
                .setDataMapping(mapping);
        Map<String, List<SObject>> filteredRecords = filterJunkRecords(
                oldRecords,
                newRecords,
                mapping.keySet(),
                contextConfiguration.getParentFieldMarker()
        );
        List<Id> parentRecordsIds = trackParents(
                filteredRecords.get(oldValue),
                filteredRecords.get(newValue),
                contextConfiguration.getParentFieldMarker()
        );

        new ReportsRelatedDataUtil(contextConfiguration)
                .configureParentsForUpdate(parentRecordsIds)
                .updateParentFields();
    }

    public static void updateComplaintWithQuestionairesData(List<SObject> oldRecords, List<SObject> newRecords) {
        Map<SObjectField, SObjectField> mapping = new Map<SObjectField, SObjectField>{
                CMPL123CME__Questionnaire__c.Reportability_Rationale__c => CMPL123CME__Complaint__c.Reportability_Rationale__c,
                CMPL123CME__Questionnaire__c.Reportability_Date__c => CMPL123CME__Complaint__c.Reportability_Date__c,
                CMPL123CME__Questionnaire__c.Name => CMPL123CME__Complaint__c.Medical_Evaluation_IDs__c,
                CMPL123CME__Questionnaire__c.Medical_Evaluator_Name__c => CMPL123CME__Complaint__c.Medical_Evaluators__c
        };
        ReportsRelatedDataUtil.ContextConfiguration contextConfiguration = new ReportsRelatedDataUtil.ContextConfiguration()
                .setChildType(CMPL123CME__Questionnaire__c.SObjectType)
                .setParentType(CMPL123CME__Complaint__c.SObjectType)
                .setParentFieldMarker(CMPL123CME__Questionnaire__c.CMPL123CME__Complaint__c)
                .setFieldsToRemoveTime(new List<SObjectField> {CMPL123CME__Questionnaire__c.Reportability_Date__c})
                .setDataMapping(mapping);
        Map<String, List<SObject>> filteredRecords = filterJunkRecords(
                oldRecords,
                newRecords,
                mapping.keySet(),
                contextConfiguration.getParentFieldMarker()
        );
        List<Id> parentRecordsIds = trackParents(
                filteredRecords.get(oldValue),
                filteredRecords.get(newValue),
                contextConfiguration.getParentFieldMarker()
        );

        new ReportsRelatedDataUtil(contextConfiguration)
                .configureParentsForUpdate(parentRecordsIds)
                .updateParentFields();
    }

    private static List<Id> trackParents(List<SObject> oldRecords, List<SObject> newRecords, SObjectField parentField) {
        Set<Id> result = new Set<Id>();
        try {
            if (null != oldRecords) {
                for (SObject childRecord : oldRecords) {
                    result.add((Id) childRecord.get(parentField));
                }
            }
            if (null != newRecords) {
                for (SObject childRecord : newRecords) {
                    system.debug('parentField--->'+parentField);
                    system.debug('childRecord.get(parentField)--->'+childRecord.get(parentField));
                    result.add((Id) childRecord.get(parentField));
                }
            }
        } catch (SObjectException ex) {
            System.debug(ex.getMessage());
        }

        return new List<Id> (result);
    }

    private static Map<String, List<SObject>> filterJunkRecords(
            List<SObject> oldRecords,
            List<SObject> newRecords,
            Set<SObjectField> fields,
            SObjectField lookupToParent
    ) {
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();

        switch on getOperationType(oldRecords, newRecords) {
            // Track insert
            when InsertOp {
                result.put(newValue, removeRecordsWithEmptyData(newRecords, fields));
            }
            // Track update
            when UpdateOp {
                // Create map of old records
                Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>(oldRecords);
                List<SObject> oldRecordsFiltered = new List<SObject>();
                List<SObject> newRecordsFiltered = new List<SObject>();
                for (SObject record : newRecords) {
                    // Track mdc
                    Boolean isNotJunk = false;
                    for (SObjectField field : fields) {
                        String newFieldValue = String.valueOf(record.get(field));
                        String oldFieldValue = String.valueOf(oldRecordsMap.get(record.Id).get(field));
                        if (newFieldValue != oldFieldValue) {
                            isNotJunk = true;
                        }
                    }
                    if (isNotJunk || parentWasChanged(oldRecordsMap.get(record.Id), record, lookupToParent)) {
                        newRecordsFiltered.add(record);
                        oldRecordsFiltered.add(oldRecordsMap.get(record.Id));
                    }

                }
                // Update data
                result.put(newValue, newRecordsFiltered);
                result.put(oldValue, oldRecordsFiltered);
            }
            // Track delete
            when DeleteOp {
                result.put(oldValue, removeRecordsWithEmptyData(oldRecords, fields));
            }
        }

        return result;
    }

    private static Boolean parentWasChanged(SObject oldRecord, SObject newRecord, SObjectField lookupToParent) {
        return (Id) oldRecord.get(lookupToParent) != (Id) newRecord.get(lookupToParent);
    }

    private static List<SObject> removeRecordsWithEmptyData(List<SObject> records, Set<SObjectField> fields) {
        List<SObject> result = new List<SObject>();
        for (SObject record : records) {
            Boolean isNotJunk = false;
            for (SObjectField field : fields) {
                if (null != record.get(field)) {
                    isNotJunk = true;
                }
            }
            if (isNotJunk) {
                result.add(record);
            }
        }

        return result;
    }

    private static Operation getOperationType(List<SObject> oldRecords, List<SObject> newRecords) {
        if (null == oldRecords && null != newRecords) {
            return Operation.InsertOp;
        } else if (null != oldRecords && null == newRecords) {
            return Operation.DeleteOp;
        }

        return Operation.UpdateOp;
    }

    /**
     * Configuration method for tracking of all parents, which should be updated.
     *
     * @param parentsIds ids of parents which should  be updated
     *
     * @return the instance of the util
     */
    @TestVisible
    private ReportsRelatedDataUtil configureParentsForUpdate(List<Id> parentsIds) {
        this.parentIds = parentsIds;

        return this;
    }

    /**
     * This method triggers an execution of all logic needed to update data.
     */
    @TestVisible
    private void updateParentFields() {
        system.debug('1---->');
        system.debug('2---->'+getDataForParentUpdate());
        update convertToSObject(getDataForParentUpdate());
    }

    /**
     * Method to convert inputted data structure into a list of SObjects.
     *
     * @param data already evaluated data structure to be transformed. The keys of outer map are ids of future SObjects.
     * Inner map is the representation of fields as a key and a values for them as a values in the map.
     *
     * @return The list which is used for DML operation.
     */
    @TestVisible
    private List<SObject> convertToSObject(Map<Id, Map<SObjectField, String>> data) {
        List<SObject> result = new List<SObject>();
        for (Id recordId : data.keySet()) {
            Map<SObjectField, String> fields = data.get(recordId);
            system.debug('data---->'+data);
            //
            SObject convertedObject = context.getParentType().newSObject();
            system.debug('convertedObject---->'+convertedObject);
            system.debug('recordId---->'+recordId);
            convertedObject.Id = recordId;
            //
            for (SObjectField field : fields.keySet()) {
                convertedObject.put(field, fields.get(field));
            }

            result.add(convertedObject);
        }

        return result;
    }

    /**
     * This method creates the data structure, which then will convert to SObjects.
     *
     * @return The keys of outer map are ids of future SObjects.
     * Inner map is the representation of fields as a key and a values for them as a values in the map.
     */
    @TestVisible
    private Map<Id, Map<SObjectField, String>> getDataForParentUpdate() {
        Map<Id, List<SObject>> data = getChildrenGroupedByParent();
        Map<Id, Map<SObjectField, String>> result = new Map<Id, Map<SObjectField, String>>();
        for (Id recordId : data.keySet()) {
            result.put(recordId, getConcatenatedDataForSObject(data.get(recordId)));
        }

        return result;
    }

    /**
     * This method converts list of records into a map of fields and their values
      * according to the settings in the context.
     *
     * @param records SObjects whose fields should be processed.
     *
     * @return Map of fields names as keys and their values.
     */
    @TestVisible
    private Map<SObjectField, String> getConcatenatedDataForSObject(List<SObject> records) {
        Map<SObjectField, String> result = new Map<SObjectField, String>();
        Map<SObjectField, SObjectField> dataMappings = context.getDataMapping();
        for (SObjectField field : dataMappings.keySet()) {
            result.put(dataMappings.get(field), getConcatenatedFields(records, field));
        }

        return result;
    }

    /**
     * Method to receive concatenated values of specified field.
     *
     * @param records Records whose fields should be processed.
     * @param field A field which should be taken for concatenation.
     *
     * @return String value for parent record.
     */
    @TestVisible
    private String getConcatenatedFields(List<SObject> records, SObjectField field) {
        List<String> results = new List<String>();
        for (SObject record : records) {
            handleFieldBeforeAdd(
                    results,
                    record,
                    field,
                    String.valueOf(records.indexOf(record) + 1)
            );
        }
        String result = String.join(results, '; ');
        if (context.getCheckFieldLengthLimitation() && result.length() > FIELD_LENGTH_LIMIT) {
            result = result.substring(0, FIELD_LENGTH_LIMIT);
        }

        return result;
    }

    /**
     * This method is for processing of child record's fields.
     * Like skipping of blank values and update the values with child records markers if needed.
     *
     * @param resultSet the list in which should be added already processed values.
     * @param record SObject records from which the value of the specified field should be added.
     * @param field marker for the value extraction.
     * @param index used for appending to the child record mark, if needed.
     */
    @TestVisible
    private void handleFieldBeforeAdd(List<String> resultSet, SObject record, SObjectField field, String index) {
        String value = String.valueOf(record.get(field));
        if (String.isBlank(value)) {
            return;
        } else if (isFieldMarkNeeded(field)) {
            String valueFormat = '{0}{1}-{2}';
            List<String> values = new List<String>{
                    context.getChildFieldMarker(),
                    index,
                    value
            };

            value = String.format(valueFormat, values);
        } else if ('DATETIME' == String.valueOf(field.getDescribe().getType())
                && context.getFieldsToRemoveTime().contains(field)) {
            value = DateTime.valueOf(value).format();
        }

        resultSet.add(value);
    }

    private Boolean isFieldMarkNeeded(SObjectField field) {
        return String.isNotBlank(context.getChildFieldMarker())
                && context.getFieldsToPopulateWithChildMarker().contains(field);
    }

    /**
     * The method for receiving lists of children records grouped by parent id.
     *
     * @return Map(Id, List(SObject)) data structure.
     */
    @TestVisible
    private Map<Id, List<SObject>> getChildrenGroupedByParent() {
        Map<Id, List<SObject>> groupedResult = new Map<Id, List<SObject>>();
        for (SObject child : getChildRecordsData()) {
            Id parentId = (Id) child.get(context.parentFieldMarker);
            List<SObject> children = groupedResult.get(parentId);
            if (null == children) {
                children = new List<SObject>();
                groupedResult.put(parentId, children);
            }

            children.add(child);
        }

        return groupedResult;
    }

    /**
     * The method for retrieving of all child records for specified parent records.
     * This method is called only once per util execution.
     *
     * @return all available data from database.
     */
    @TestVisible
    private List<SObject> getChildRecordsData() {
        final String IS_CLONED_CONDITION_FORMAT = ' AND {0}.{1} = false';
        String isClonedCondition = '';
        SObjectField isClonedFieldMarker = context.getIsClonedParentMarker();
        if (null != isClonedFieldMarker) {
            List<String> args = new List<String>{
                    context.getParentFieldMarker().getDescribe().getRelationshipName(),
                    isClonedFieldMarker.getDescribe().getName()
            };
            isClonedCondition = String.format(IS_CLONED_CONDITION_FORMAT, args);
        }

        List<String> arguments = new List<String>{
                String.join(getFieldNames(context.getDataMapping().keySet(), context.getParentFieldMarker()), ','),
                context.getChildType().getDescribe().getName(),
                context.getParentFieldMarker().getDescribe().getName(),
                isClonedCondition
        };
        return Database.query(String.format(QUERY_FORMAT, arguments));
    }

    /**
     * The method used to create the list of all needed fields which should be queried during a SOQL.
     *
     * @param fields fields from mapping context
     * @param parentField Marker field which is used then to match a child to parent relationship.
     *
     * @return The list of string API names of fields.
     */
    @TestVisible
    private List<String> getFieldNames(Set<SObjectField> fields, SObjectField parentField) {
        List<String> names = new List<String>();
        for (SObjectField field : fields) {
            names.add(field.getDescribe().getName());
        }
        names.add(parentField.getDescribe().getName());

        return names;
    }

    /**
     * The class to store all needed data for the setup of context for util execution.
     * It is instantiated only once per util execution to avoid context overloading issue.
     */
    @TestVisible
    class ContextConfiguration {
        @TestVisible
        private SObjectType childType;
        @TestVisible
        private SObjectType parentType;
        @TestVisible
        private SObjectField parentFieldMarker;
        @TestVisible
        private String childFieldMarker;
        @TestVisible
        private List<SObjectField> fieldsToPopulateWithMarker;
        @TestVisible
        private List<SObjectField> fieldsToRemoveTime;
        @TestVisible
        private Boolean checkFieldLengthLimitation = false;
        @TestVisible
        private SObjectField isClonedParentMarker;
        /**
         * Key - child field;
         * Value - parent field;
         */
        @TestVisible
        private Map<SObjectField, SObjectField> fieldMapping;

        @TestVisible
        String getChildFieldMarker() {
            return this.childFieldMarker;
        }

        @TestVisible
        List<SObjectField> getFieldsToRemoveTime() {
            return (this.fieldsToRemoveTime != null ? this.fieldsToRemoveTime : new List<SObjectField>());
        }

        @TestVisible
        List<SObjectField> getFieldsToPopulateWithChildMarker() {
            return this.fieldsToPopulateWithMarker;
        }

        @TestVisible
        SObjectField getParentFieldMarker() {
            return this.parentFieldMarker;
        }

        @TestVisible
        SObjectType getChildType() {
            return this.childType;
        }

        @TestVisible
        SObjectType getParentType() {
            return this.parentType;
        }

        @TestVisible
        Map<SObjectField, SObjectField> getDataMapping() {
            return this.fieldMapping;
        }

        @TestVisible
        Boolean getCheckFieldLengthLimitation() {
            return this.checkFieldLengthLimitation;
        }

        @TestVisible
        SObjectField getIsClonedParentMarker() {
            return this.isClonedParentMarker;
        }

        @TestVisible
        ContextConfiguration setFieldsToRemoveTime(List<SObjectField> fields) {
            if (null == this.fieldsToRemoveTime) {
                this.fieldsToRemoveTime = fields;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setChildFieldMarker(String value) {
            if (null == this.childFieldMarker) {
                this.childFieldMarker = value;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setFieldsToPopulateWithMarker(List<SObjectField> fields) {
            if (null == this.fieldsToPopulateWithMarker) {
                this.fieldsToPopulateWithMarker = fields;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setParentFieldMarker(SObjectField field) {
            if (null == this.parentFieldMarker) {
                this.parentFieldMarker = field;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setChildType(SObjectType source) {
            if (null == this.childType) {
                this.childType = source;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setParentType(SObjectType target) {
            if (null == this.parentType) {
                this.parentType = target;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setDataMapping(Map<SObjectField, SObjectField> fieldMapping) {
            if (null == this.fieldMapping) {
                this.fieldMapping = fieldMapping;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setCheckFieldLengthLimitation(Boolean checkFieldLengthLimitation) {
            if (false == this.checkFieldLengthLimitation) {
                this.checkFieldLengthLimitation = checkFieldLengthLimitation;
            }

            return this;
        }

        @TestVisible
        ContextConfiguration setIsClonedParentMarker(SObjectField value) {
            if (null == this.isClonedParentMarker) {
                this.isClonedParentMarker = value;
            }

            return this;
        }
    }
}