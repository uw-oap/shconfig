Set( $CorrespondAddress, '{{rt_correspond_address}}' );
Set( $rtname, 'FIXME' );
Set( $WebPort, '443' );
Set( $Organization, '{{rt_webdomain}}' );

Set( $DatabaseType, 'mysql' );
Set( $DatabasePort, '' );
Set( $DatabaseHost, '{{rt_db_host}}' );
Set( $DatabaseName, '{{rt_db_name}}' );
Set( $DatabaseUser, '{{secrets_rt_db_user}}' );
Set( $DatabasePassword, '{{secrets_rt_db_pass}}' );
Set( $DatabaseAdmin, 'root' );
Set( %DatabaseExtraDSN,
     mysql_ssl => 1,
     mysql_ssl_optional => 1,
    );

Set( $SendmailPath, '/usr/sbin/sendmail' );
Set( $WebDomain, '{{rt_webdomain}}' );
Set( $CommentAddress, '{{rt_correspond_address}}' );
Set( $OwnerEmail, '{{shconfig_email}}' );
Set($Timezone, 'FIXME');
Set($WebRemoteUserAuth, '1');
Set($WebFallbackToRTLogin, '1');
Plugin( 'RT::Extension::AutomaticAssignment' );
Set($ParseNewMessageForTicketCcs, '1');
Set($RTAddressRegexp,
    qr{^
    FIXME
       )$}ix);

# TODO need to turn on full-text index first
Set( %FullTextSearch,
    Enable     => 1,
    Indexed    => 1,
    Table      => 'AttachmentsIndex',
);


Set( $ArticleOnTicketCreate, '1' );
Set( $PreferRichText, '1' );
Set( $MessageBoxRichText, '1' );
Set( $MaxInlineBody, 0 );
Set( $TreatAttachedEmailAsFiles, 0);
Set(@ReferrerWhitelist, qw(FIXME:443)),

Set(%ExternalStorage,
        Type => 'Disk',
        Path => '{{rt_dir}}/var/attachments',
);
Set($ExternalStorageCutoffSize, 100_000);


1;
