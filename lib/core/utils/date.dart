String ymd(DateTime d) =>
    "\${d.year.toString().padLeft(4,'0')}-\${d.month.toString().padLeft(2,'0')}-\${d.day.toString().padLeft(2,'0')}";
