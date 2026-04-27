#!/bin/bash

# Update and install required packages
yum update -y
yum install -y httpd php wget tar xz

# Start and enable HTTP service
systemctl start httpd
systemctl enable httpd

# Permissions and ownership settings for Apache
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

wget -O /var/www/html/aws.gif https://aws-jam-challenge-resources.s3.amazonaws.com/s3-mountpoint/aws.gif

# PHP script to display Instance ID, Availability Zone, and the Image
cat << 'EOF' > /var/www/html/index.php
<!DOCTYPE html>
<html>
<body>
<center>
  <h2>Johor-Singapore Causeway Traffic</h2>
  <script type="text/javascript">
  <!-- Encrypted -->
  <!--
  document.write(unescape('%3c%69%6d%67%20%73%72%63%3d%22%61%77%73%2e%67%69%66%22%20%61%6c%74%3d%22%41%57%53%20%49%6d%61%67%65%22%3e'));
  //-->
  </script>

  <?php
  # Function to get a token for IMDSv2
  function get_imdsv2_token() {
      $ch = curl_init();
      curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/api/token");
      curl_setopt($ch, CURLOPT_HTTPHEADER, array("X-aws-ec2-metadata-token-ttl-seconds: 21600"));
      curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
      curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
      $token = curl_exec($ch);
      curl_close($ch);
      return $token;
  }

  # Function to get metadata using IMDSv2
  function get_instance_metadata($path, $token) {
      $ch = curl_init();
      curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/meta-data/" . $path);
      curl_setopt($ch, CURLOPT_HTTPHEADER, array("X-aws-ec2-metadata-token: " . $token));
      curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
      $result = curl_exec($ch);
      curl_close($ch);
      return $result;
  }

  $token = get_imdsv2_token();

  # Get the instance ID and Availability Zone using IMDSv2
  $instance_id = get_instance_metadata("instance-id", $token);
  $zone = get_instance_metadata("placement/availability-zone", $token);
  ?>
  <h2>EC2 Instance ID: <?php echo $instance_id ?></h2>
  <h2>Availability Zone: <?php echo $zone ?></h2>
</center>
</body>
</html>
EOF

# Install FFmpeg if not already installed
if ! command -v ffmpeg &> /dev/null
then
    cd /usr/local/bin
    mkdir -p ffmpeg
    cd ffmpeg
    wget https://aws-jam-challenge-resources.s3.amazonaws.com/s3-mountpoint/ffmpeg-git-amd64-static.tar.xz
    tar -xf ffmpeg-git-amd64-static.tar.xz --strip-components=1
    ln -s /usr/local/bin/ffmpeg/ffmpeg /usr/bin/ffmpeg
fi

# Verify FFmpeg installation
ffmpeg -version