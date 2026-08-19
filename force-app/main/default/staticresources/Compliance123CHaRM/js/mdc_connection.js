////////////////////////////////////////////////////////
// mdc.sfdc.Connection
////////////////////////////////////////////////////////
mdc.sfdc.Connection.prototype.buildQuery = function(options) {

	var sb = new StringBuilder();
	
	sb.append("SELECT ");
	sb.append(options.fields.toString(","));
	sb.append(" FROM ");
	sb.append(options.table);

	if (options.whereClauses)
       {
       	if (options.whereClauses.where && options.whereClauses.where.length > 0)
           {
           	sb.append(" WHERE ");
               this.__buildWhereClauseString(options.whereClauses, sb);
           }
       }
       
       if (options.orWhereClauses)
       {
        if (options.orWhereClauses.where && options.orWhereClauses.where.length > 0)
        {
            sb.append(" OR ");
            this.__buildWhereClauseString(options.orWhereClauses, sb);
        }
       }
       
       if (options.orderBy)
       {
        sb.append(" ORDER BY " + options.orderBy);
       }
       
       if (options.limit)
       {
        sb.append(" LIMIT " + options.limit);
       }

       return sb.toString();
};

mdc.sfdc.Connection.prototype.__buildWhereClauseString = function(whereClauses, whereClauseString)
{
	whereClauseString.append("(");
    
    for (var i = 0; i < whereClauses.where.length; i++)
    {
        if (i > 0)
        {
            whereClauseString.append(" ");
            whereClauseString.append(whereClauses.conjunction ? whereClauses.conjunction : "AND");
            whereClauseString.append(" ");
        }
        
        var whereClause = whereClauses.where[i];
        
        if (whereClause.where)
        {
            whereClauseString.append(this.__buildWhereClauseString(whereClause, new StringBuilder()));
            continue;
        }
        
        whereClauseString.append("(");
        whereClauseString.append(whereClause.field);
        
        if (whereClause.not)
        {
             if (whereClause.operator.contains("="))
             {
             	whereClauseString.append("!=");
             }
             else if (whereClause.operator.contains("LIKE"))
             {
                 whereClauseString.append(" NOT LIKE ");
             }
        }
        else
        {
            whereClauseString.append(whereClause.operator);
        }

           if (typeof (whereClause.value) == "object")
           {
             whereClauseString.append("(");
             whereClauseString.append(this.buildSelectQuery(whereClause.value));
             whereClauseString.append(")");
           }
           else
           {
            whereClauseString.append(whereClause.value);
           }
        
        whereClauseString.append(")");
    }
    
    whereClauseString.append(")");

    return whereClauseString.toString();
};
	
	
mdc.sfdc.Connection.prototype.countQuery = function(queryString)
{
    try
    {
        return sforce.connection.query(queryString).size;
      	}
    catch(error)
    {
         console.info("ERROR: mdc.sfdc.Connection.prototype.countQuery: " + queryString + ": " + error.stack);
    }
    
    return 0;
};

	
//mdc.sfdc.Connection.prototype.query = function(queryString)
//{
// 	var records = [];
//    
//    try
//    {
//        var queryResult = sforce.connection.query(queryString);
//        records = queryResult.getArray("records");
//        
//           while (queryResult.done !== "true")
//           {
//            queryResult = sforce.connection.queryMore(queryResult.queryLocator);
//            records = records.concat(queryResult.getArray("records"));
//           }
//      	}
//    catch(error)
//    {
//		console.info("ERROR: mdc.sfdc.Connection.prototype.query: " + queryString + ": " + error + ": " + error.stack);
//		return [];
//    }
//        
//	return records;
//};


mdc.sfdc.Connection.prototype.query = function(queryString, batchCallback) {
 	var records = [];
    
    try
    {
        var queryResult = sforce.connection.query(queryString);
        
        if (batchCallback) {
        	batchCallback(queryResult);
        	return;
        }
        
        records = queryResult.getArray("records");
        
        while (queryResult.done !== "true") {
            queryResult = sforce.connection.queryMore(queryResult.queryLocator);
       	    records = records.concat(queryResult.getArray("records"));
    	}
    }
    catch(error)
    {
		console.info("ERROR: mdc.sfdc.Connection.prototype.query: " + queryString + ": " + error.stack);
		return [];
    }
        
	return records;
};
	

mdc.sfdc.Connection.prototype.queryMore = function(queryLocator, batchCallback) {
    try
    {
    	var queryResult = sforce.connection.queryMore(queryLocator);
       	batchCallback(queryResult)
       	
    }
    catch(error)
    {
		console.info("ERROR: mdc.sfdc.Connection.prototype.query: " + queryString + ": " + error.stack);
		return [];
    }
};	
	
mdc.sfdc.Connection.prototype.update = function(updateArray)
{
    var result = null;
    
    try
    {
        result = sforce.connection.update(updateArray); 
    } 
    catch(error)
    {
         console.info("mdc.sfdc.Connection.prototype.update: " + error.stack);
    }

       if (result.length > 0 && result[0].success === "false")
       {
       	console.info("Update records failed with error: " + result[0].errors.message);
       }
    
    return result;
};

mdc.sfdc.Connection.prototype.upsert = function(upsertArray)
{
       var result = null;
       
       try
    {
        result = sforce.connection.upsert("id", upsertArray); 
    } 
    catch(error)
    {
      		console.info("mdc.sfdc.Connection.prototype.upsert: " + error.stack);
    }

       if (result === null || (result.length > 0 && result[0].success === "false"))
       {
              console.info("Save records failed with error: " + result[0].errors.message);
       }
    
    return result;
};

mdc.sfdc.Connection.prototype.delete = function(deleteIdArray)
{
       var result = null;
       
       try
    {
        result = sforce.connection.deleteIds(deleteIdArray);  
    } 
    catch(error)
    {
        console.info("mdc.sfdc.Connection.prototype.delete: " + error.stack);
    }

       if (!result)
       {
        console.info("Delete records failed");
       }
       else if (result.length > 0 && result[0].success === "false")
       {
           console.info("Delete records failed with error: " + result[0].errors.message);
       }
    
    return result;
};
