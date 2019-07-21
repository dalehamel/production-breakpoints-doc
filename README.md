[![Build Status](https://travis-ci.org/dalehamel/usdt-report-doc.svg?branch=master)](https://travis-ci.org/dalehamel/usdt-report-doc)

[![Docker Repository on Quay](https://quay.io/repository/dalehamel/usdt-report-doc/status "Docker Repository on Quay")](https://quay.io/repository/dalehamel/usdt-report-doc?tab=builds)
# USDT Report

This is the backend page for https://blog.srvthe.net/usdt-report-doc/,
a report I have prepared of my exploration into USDT tracing in production.

I believe that this is relatively new territory, as up until now existing tracing
in ruby has been limited to an "all or nothing" sort of approach, of attaching to every
function in ruby, causing a guaranteed overhead to the application.

This debugging tax may be a reasonable compromise in development environments, but
why should it need to be so in production?

USDT tracing offers a means of only analyzing code that needs to be analyzed, which
reduce the overhead of collecting metrics.

