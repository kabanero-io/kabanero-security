<?php 
    if ('PUT' === $_SERVER['REQUEST_METHOD']) {
      $header = "/staging";
      $rootpath = "/var/www/sigstore";  // default root path
      $putdata=file_get_contents('php://input');
      $uri=$_SERVER['REQUEST_URI'];
      if(($putdata!=FALSE) && (startsWith($uri, $header)) && (strpos($uri, "..")==FALSE)) {
        $datapath = $rootpath . "/html/signatures"; // data directory
        $zipfile = $rootpath . "/data.zip";  //zipped file of data directory.
        $jsonfile = $rootpath . "/data-secret.json"; // secret json file
        $fname = $datapath . substr($uri, strlen($header)); 
        $path = substr($fname, 0, strrpos($fname, '/'));
        if(createPath($path)) {
          if(file_put_contents($fname, $putdata)===FALSE) {
            error_log("error: file copy");
            http_response_code(507);
          } else {
            $storesecret = getenv("SIGSTORE_SAVE_SECRET");
            //default is false
            if (strcasecmp("true", $storesecret) == 0) {
              if (createZipFile($datapath, $zipfile)) {
                if (createSecretJson($zipfile, $jsonfile)) {
                  if (setSecret($jsonfile)) {  
                    echo "Result:Success: stored to secret ";
                    http_response_code(201);
                  } else {
                    error_log("error: store secret");
                    http_response_code(507);
                  }
                }
              }  
            } else {
              echo "Result:Success: stored to local disk only";
              http_response_code(201);
            }
          }
        } else {
          error_log("error: path creating");
          http_response_code(507);
        }
      } else {
        http_response_code(400);
      }
    }
    function createPath($path) {
      if (is_dir($path)) return true;
      $prev_path = substr($path, 0, strrpos($path, '/', -2) + 1 );
      $return = createPath($prev_path);
      return ($return && is_writable($prev_path)) ? mkdir($path) : false;
    }

    function createZipFile($rootpath, $zipfile) {
      $zip = new ZipArchive();
      $zip->open($zipfile, ZipArchive::CREATE | ZipArchive::OVERWRITE);
      $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($rootpath), RecursiveIteratorIterator::LEAVES_ONLY);

      foreach ($files as $name => $file) {
	// no need to zip directories.	
        if (!$file->isDir()) {
          $filepath = $file->getRealPath();
          $relativepath = substr($filepath, strlen($rootpath) + 1);
          $zip->addFile($filepath, $relativepath);
        }
      }
      $zip->close();
      return true;
    }

    function createSecretJson($zipfile, $jsonfile) {
      $data = file_get_contents($zipfile); 
      if (strlen($data) > 0) {
        $encoded = base64_encode($data);       
        $contents = '{"apiVersion": "v1","kind": "Secret","metadata":{"name": "signature-data"},"data": {"stored.zip": ';
        $len = file_put_contents($jsonfile, $contents . '"' . $encoded . '"}}', LOCK_EX);
        if ($len == 0) {
          error_log("error: failed to create a secret. file creation error");
          return false;	
	} elseif ($len > 1000000) {
          error_log("error: failed to create a secret. data is too large to store.");	
          return false;	
        } 
        return true;
      }
      error_log("failed to create a secret. zip file read error");
      return false;
    }      
    
    function setSecret($jsonfile) {
      $server="https://" . getenv("KUBERNETES_SERVICE_HOST") . ":" . getenv("KUBERNETES_SERVICE_PORT");
      $token=file_get_contents("/var/run/secrets/kubernetes.io/serviceaccount/token");
      $namespace=file_get_contents("/var/run/secrets/kubernetes.io/serviceaccount/namespace");
      $name="signature-data";
      if (existSecret($server, $namespace, $token, $name)) {
        $command='curl -k -X PUT -d "@'.  $jsonfile . '" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer ' . $token . '" ' . $server . '/api/v1/namespaces/' . $namespace . '/secrets/' . $name;
      } else {
        $command='curl -k -X POST -d "@'.  $jsonfile . '" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer ' . $token . '" ' . $server . '/api/v1/namespaces/' . $namespace . '/secrets';
      }
      exec($command, $output, $return_var);
      if ($return_var==0) {
        if (isSuccess($output)) {
          return true;
        }
        // error case
        error_log("error: failed to set secret in a REST call.");
        return false;
      }
      // fail curl
      error_log("error: failed to set secret in cURL call.");
      return false;
    }

    function existSecret($server, $namespace, $token, $name) {
      $command='curl -k -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer ' . $token . '" ' . $server . '/api/v1/namespaces/' . $namespace . '/secrets/' . $name;
      exec($command, $output, $return_var);
      if ($return_var ==0) {
        if (isSuccess($output)) {
          return true;
        }
      }
      return false;
    }

    function isSuccess($output) {
      foreach($output as $value) {
        if ((strpos($value, '"status"') !== false) && (strpos($value, ':') !== false) && (strpos($value, '"Failure"') !== false)) {
          return false;
        }
      }
      return true;
    }

    function startsWith($src, $dest) {
      return (substr($src, 0, strlen($dest)) === $dest);
    }
?>
