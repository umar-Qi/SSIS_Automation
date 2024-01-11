#r "nuget: System.Data.SqlClient, 4.7.0"
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

var scriptArgs = Environment.GetCommandLineArgs();

if (scriptArgs.Length > 0)
{
	string ServerName = scriptArgs[2];
	string CatalogName = scriptArgs[3];
	string FolderName = scriptArgs[4];
	string ProjectName = scriptArgs[5];
	string fileName = scriptArgs[6];
	FileInfo fi = new FileInfo(fileName);
	string FilePath = fi.FullName;
	string justFileName = Path.GetFileNameWithoutExtension(FilePath);


            // Connection string to SSISDB 
	    Console.WriteLine("Building connection to the server ...."); 

            var connectionString = "Data Source="+ServerName+";Initial Catalog="+CatalogName+";Integrated Security=True;MultipleActiveResultSets=false";



            using (var sqlConnection = new SqlConnection(connectionString))

            {

                sqlConnection.Open();

		Console.WriteLine("Connected to the server ....");

                var sqlCommand = new SqlCommand

                {

                    Connection = sqlConnection,

                    CommandType = CommandType.StoredProcedure,

                    CommandText = "[catalog].[deploy_packages]"

                };

		Console.WriteLine("Searching Package ....");

                var packageData = Encoding.UTF8.GetBytes(File.ReadAllText(FilePath));



                // DataTable: name is the package name without extension and package_data is byte array of package.  

                var packageTable = new DataTable();

                packageTable.Columns.Add("name", typeof(string));

                packageTable.Columns.Add("package_data", typeof(byte[]));

                packageTable.Rows.Add(justFileName, packageData);



                // Set the destination project and folder which is named Folder and Project.  
		Console.WriteLine("Deploying package to the given project ....");

                sqlCommand.Parameters.Add(new SqlParameter("@folder_name", FolderName));

                sqlCommand.Parameters.Add(new SqlParameter("@project_name", ProjectName));

                sqlCommand.Parameters.Add(new SqlParameter("@packages_table", packageTable));


                var result = sqlCommand.Parameters.Add("RetVal", SqlDbType.Int);

                result.Direction = ParameterDirection.ReturnValue;



                try

                {

                    sqlCommand.ExecuteNonQuery();

                    Console.WriteLine(result.Value);
		Console.WriteLine("Deployment Complete ....");

                }
                catch (Exception excp)

                {

                    Console.WriteLine(excp.Message);

                }

            }
}else{
	Console.WriteLine("No path found, Provide the parameters");
}
