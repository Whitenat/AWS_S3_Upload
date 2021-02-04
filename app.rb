require 'aws-sdk'
#assume the role
#arn:aws:iam::829928713858:role/s3-bucket-role
NO_SUCH_BUCKET = "The bucket '%s' does not exist!"

role_credentials = Aws::AssumeRoleCredentials.new(
  client: Aws::STS::Client.new,
  role_arn: "arn:aws:iam::829928713858:role/s3-bucket-role",
  role_session_name: "s3-upload-session"
)

s3 = Aws::S3::Client.new(region: "us-east-2", credentials: role_credentials)
bucket_name = nil


if (ARGV.length < 1)
	operation = 'help' 
else
	operation = ARGV[0]
end

# The operation to perform on the bucket
 # default
bucket_name = ARGV[1] if (ARGV.length > 1)

# The file name to use with 'upload'
file_name = nil
file_name = ARGV[2] if (ARGV.length > 2)

new_name = nil
new_name = ARGV[3] if (ARGV.length > 3)


case operation
when 'upload_song'
  if file_name == nil
    puts "You must enter the name of the file to upload to S3!"
    exit
  end

  puts "Uploading: #{file_name}..."
 	s3.put_object({
	  bucket: bucket_name, 
	  key: file_name
	})
	puts "Upload complete."

when 'upload_album'
	if file_name == nil
    puts "You must enter the name of the file to upload to S3!"
    exit
  end

	songs = Dir.entries(file_name)

 	songs.each do |song|
 		next if song == '.' or song == '..'
 		puts "Uploading: #{file_name}#{song}..."
 		s3.put_object({
		  bucket: bucket_name, 
		  key: "#{file_name}#{song}"
		})
 	end
 	puts "Upload complete."

when 'upload_artist'
	if file_name == nil
    puts "You must enter the name of the file to upload to S3!"
    exit
  end

  artist = Pathname(file_name)
  albums = artist.children()

	albums.each do |album|
		next if !album.directory?
		Dir.each_child(album) do |song|
	      puts "Uploading: #{album}/#{song}..."
	      s3.put_object( bucket: bucket_name, key: "#{album}/#{song}")
	  end
	end
	puts "Upload complete."

when 'rename'
  if file_name == nil
    puts "You must enter the name of the file to rename!"
    exit
  end

 	s3.copy_object({
 		bucket: bucket_name, 
	  copy_source: "/#{bucket_name}/#{file_name}", 
	  key: new_name,
 	})
 	s3.delete_object({
	  bucket: bucket_name, 
	  key: file_name, 
	})
	puts "Rename complete."


when 'list'
	objects = s3.list_objects_v2({
		bucket: bucket_name
	}).contents

	if objects.length > 0
		objects.each do |object|
			puts object.key
		end
	end

when 'help'
	def help_message
	 <<~HELP
      To List the contents of the bucket: ruby app.rb list [bucket name]
      To Rename a file in the bucket:     ruby app.rb rename [bucket name] [file name] [new name]
      To Upload a Song:                   ruby app.rb upload_song [bucket name] [file name]
      To Upload an Album:                 ruby app.rb upload_album [bucket name] [file name]
      To Upload an Artist:                ruby app.rb upload_artist bucket name] [file name]
    HELP
  end
  puts help_message

else
  puts "Unknown operation: '%s'!" % operation
end
