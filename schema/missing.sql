--
-- Name: build_status_recent_500; Type: VIEW; Schema: public; Owner: eximbuild
--

CREATE VIEW build_status_recent_500 AS
    SELECT bs.sysname, bs.status, bs.snapshot, bs.stage, bs.conf_sum, bs.branch, bs.changed_this_run, bs.changed_since_success, bs.log_archive_filenames, bs.build_flags, bs.report_time, bs.log FROM build_status AS bs WHERE ((build_status.snapshot + '3 mons'::interval) > ('now'::text)::timestamp(6) with time zone);

ALTER TABLE public.build_status_recent_500 OWNER TO eximbuild;

--
-- Name: nrecent_failures; Type: VIEW; Schema: public; Owner: eximbuild
--

CREATE VIEW nrecent_failures AS
    SELECT build_status.sysname, build_status.snapshot, build_status.stage, build_status.conf_sum, build_status.branch, build_status.changed_this_run, build_status.changed_since_success, build_status.log_archive_filenames, build_status.build_flags, build_status.report_time, build_status.log FROM build_status WHERE ((((build_status.stage <> 'OK'::text) AND (build_status.stage !~~ 'CVS%'::text)) AND (build_status.report_time IS NOT NULL)) AND ((build_status.snapshot + '3 mons'::interval) > ('now'::text)::timestamp(6) with time zone));

ALTER TABLE public.nrecent_failures OWNER TO eximbuild;
