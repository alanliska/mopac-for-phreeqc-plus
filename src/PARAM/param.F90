! Molecular Orbital PACkage (MOPAC)
! Copyright (C) 2021, Virginia Polytechnic Institute and State University
!
! MOPAC is free software: you can redistribute it and/or modify it under
! the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! MOPAC is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public License
! along with this program.  If not, see <https://www.gnu.org/licenses/>.
 
 program  param
    use param_global_C, only : numvar, large, power, ifiles_8, &
    & contrl, fnsnew, nfns, xparamp, diffns, fns, penalty, &
    save_parameters
!
    use molkst_C, only : tdump, maxatoms, is_PARAM, numat, jobnam, &
     moperr, method_mndo, method_am1, method_pm3, method_mndod, fract, &
     norbs, mpack, nvar, n2elec, keywrd, uhf, l123, run, method_pm6_d3, &
     method_pm6, lm61, gui, method_rm1, tleft, emin, iflepo, escf, l_feather, &
     method_pm6_dh_plus, method_pm6_dh2, method_pm7, trunc_1,  &
     trunc_2, method_pm6_d3h4, method_pm6_d3_not_h4, verson, n_methods, methods, &
     methods_keys, method_pm7_hh, method_pm7_minus, method_pm7_ts, method_pm6_dh2x, &
     method_pm6_d3h4x, backslash, step, mozyme, density
    use cosmo_C, only : iseps, nspa, useps, solv_energy
    use meci_C, only : maxci
!
    use common_arrays_C, only:  atmass, na, nb, nc, geoa, p, nw, pa, pb, &
      pdiag, cell_ijk
!
    use chanel_C, only : ir, iw, ilog, job_fn, input, iarc, ifiles_1
    use funcon_C, only : fpc_1, fpc_2, a0, ev, fpc_6, fpc_7, fpc_8, &
    & fpc_9, fpc_10, fpc_5
    use conref_C, only : fpcref 
    use meci_C, only : nmos
    use parameters_C, only: f0sd, g2sd, tore, ios, iop, iod, f0sd_store, g2sd_store, &
      zs, t_par, xfac, alpb
    USE journal_references_C, only : allref
    implicit none
    logical :: opend, exists, quotation_mark
    integer :: i, j, l, k, loop, maxcyc, n9, n4, n1
    double precision :: sum
    character :: text*2000, idate*24
  !
  !
  !.. External Calls ..
    external finish, getdat, fdate
  !
  !.. External Functions ..
    double precision, external :: Reada
  !
  !.. Intrinsic Functions ..
    intrinsic Index
#ifdef MKL
      integer :: num_threads
      integer, external :: mkl_get_max_threads
#endif
  !
  ! ... Executable Statements ...
  !
  !
    moperr = .false.
    useps = .false.
 !   method_PM8 = .false.
    cell_ijk = 0
    step = 0.d0
    mozyme = .false.
    xfac = 0.d0
    alpb = 0.d0
    density = 0.d0
    fnsnew = 0.d0
    fract = 0.d0
    emin = 0.d0
    escf = 0.d0
    solv_energy = 0.d0
    iflepo = 0
    l_feather = (method_PM7 .or. index(keywrd, " MOZ") /= 0 .and. (index(keywrd, " PM6") /= 0))
    num_threads = mkl_get_max_threads()
    call mkl_set_num_threads(num_threads)
    verson = "18.000W"
    t_par(1)  = "Used in ccrep for scalar correction of C-C triple bonds."
    t_par(2)  = "Used in ccrep for exponent correction of C-C triple bonds."
    t_par(3)  = "Used in ccrep for scalar correction of O-H term."
    t_par(4)  = "Used in ccrep for exponent correction of C-C triple bonds."
    t_par(7)  = "Used in dftd3 to set ""s6""  in D3H4"
    t_par(8)  = "Used in dftd3 to set ""alp"" in D3H4"
    t_par(9)  = "Used in dftd3 to set ""rs6"" in D3H4"
    gui = .false.
    ifiles_8 = 8
    ifiles_1 = ifiles_8
    power = 2.0d0
    tore = ios + iop + iod
    is_PARAM = .true.
    run = 1
      call fbx   ! Factorials and Pascal's triangle (pure constants)
      call fordd ! More constats, for use by MNDO-d
  !
  !  one-time construction of arrays in setalp
  !
  !  call setalp_init
  !  time0 = second (1)
  !
  !  Disable MOPAC test for the presence of parameters
  !
    do i = 1, 107
      do j = 1, 5
        allref (i, j) (1:1) = " "
      end do
    end do
  !
  ! Read in all the data in the file "<filename>.dat", and put it
  ! in an internal file. 
  !
    call getdat(input, ifiles_8)
    if (moperr) stop
    job_fn = Trim (jobnam) // ".dat"
    inquire (file=job_fn, exist=exists)
    if (.not. exists) then
      open(unit=ifiles_8, file=trim(jobnam)//'.out') 
      write(ifiles_8,'(//10x,a,/10x,a)')"File: """//trim(job_fn)//"""", &
      "does not exist in this folder, therefore this job cannot be run."
      call finish
    end if
    job_fn = Trim (jobnam) // ".mop"
    inquire (file=job_fn, exist=exists)
    if (exists) then
      open(unit=ifiles_8, file=trim(jobnam)//'.out') 
      write(ifiles_8,'(a)')"File """//trim(job_fn)//""" exists, therefore job cannot be run."
      call finish
    end if
    write(*,'(a)')" Running job: """//trim(jobnam)//""""
  !
  !  Open output results
  !
    i = len_trim(jobnam) 
    k = Index (contrl, "OUT=")
    if (k /= 0) then
      j = Index (contrl(k+4:), " ")
      text = contrl (k+4:k+j+2) // jobnam (:i) // ".out"
    else
      text = jobnam (:i) // ".out"
    end if
  97  open (unit=ifiles_8, file=text, status="UNKNOWN", iostat=i)
    if (i /= 0) then
      write(0,*)" Output file '"//trim(text)//"' is busy.  Correct the fault or kill this job"
      call sleep (10)
      go to 97
    end if
    goto 100
  !
  !  Open input data set
  !
100 rewind (input)
    i = 0
    do
      read (input, "(A120)") text
      i = i + 1
      if (text(1:1) /= "*") exit
      write (ifiles_8,"(a)") Trim(text)
    end do
    close (ir)
    ir = input
    rewind (ir)
  !
  !  Read in keywords for PARAM control
  !
    read (ir, "(a)",end = 99, err = 98) contrl
    do
      i = Index(contrl," +") + Index(contrl," &")
      if ( i /= 0) then
        contrl(i + 1:i + 1) = " "
        text = " "
        read (ir, "(a)",end = 99, err = 98) text
        if (text == " ") cycle
        do 
          if (text(1:1) /= " ") exit
          text = text(2:)
        end do
        if (text(1:1) == '"') then
          contrl(len_trim(contrl) + 1:) = trim(text)
        else
          contrl(len_trim(contrl) + 1:) = " "//trim(text) 
        end if
      else
        exit
      end if
    end do

  !
  !  Force character 1 to be a space
  !
    if (contrl(1:1) /= " ") then
      text = " " // trim(contrl)
      contrl = trim(text)
    else
      text = trim(contrl)
    end if
    call upcase (contrl, len_trim(contrl))
    j = 1
    do 
      l = Index (contrl(j:), '"') + j
      if (l /= j) then
!
!  Find a quotation mark - if found, preserve the case of the text between quotation marks
!
        k = Index (contrl(l:), '"') + l
        if (k /= l) then
          contrl(l:k) = text(l:k)
        else
          if (len_trim(text(l - 1:)) < 20) then
            write (ifiles_8,"(10x, a)") &
              "Unmatched quotation marks in PARAM keyword line near: '"//trim(text(max(1,l - 20):))//"'"
          else
            write (ifiles_8,"(10x, a)") "Unmatched quotation marks in PARAM keyword line near: '"//trim(text(l - 1:))//"'"
          end if
          write (ifiles_8,'(10x,a)') "Complete keyword:"
          j = len_trim(text)
          write(ifiles_8,'(a)')trim(text)
          call finish
        end if
        j = k + 1
      else
        exit
      end if
    end do
!
! Find an equals sign. Then find the first space that is not in a quoted string.
!
    j = 1
    quotation_mark = .false.
    k = len_trim(contrl)
    do i = 1, k
      j = j + 1
      if (j > k) exit
      if (contrl(j:j) == '=') then
        do l = j + 1, k
          if (contrl(l:l) == " " .and. .not. quotation_mark) exit
          if (contrl(l:l) == '"') quotation_mark = (.not. quotation_mark)
        end do
!
!  Preserve the case of the text after the equals sign in this keyword.
!
        contrl(j:l - 1) = text(j:l - 1)
        j  = l
      end if
    end do

!
!  Replace backslash with forward-slash 
!
    do i = 1, len_trim(contrl)
      if (contrl(i:i) == backslash) contrl(i:i) = "/"
    end do
    trunc_1 = 7.0d0
    trunc_2 = 0.22d0
!
!   HERE IS WHERE THE MAXIMUM NUMBER OF ATOMS IN ANY SYSTEM IS SET
!
    if (Index(contrl," EPS") /= 0) then
      n1 = 20             !  Number of atoms with 1 basis function
      n4 = 20             !  Number of atoms with 4 basis functions
      n9 = 10             !  Number of atoms with 9 basis functions
      iseps = .true.
      nspa = 42
      lm61 = 45*n9 + 10*n4 + n1
    else
      n1 = 200            !  Number of atoms with 1 basis function
      n4 = 304            !  Number of atoms with 4 basis functions
      n9 = 50             !  Number of atoms with 9 basis functions
      lm61 = 0
      iseps = .false. 
    end if
    
!
!
    maxatoms = n1 + n4 + n9
    call setup_mopac_arrays(maxatoms, 1)
    pdiag = 0.d0
    allocate(nw(maxatoms)) 
    norbs = 9*n9 + 4*n4 + n1
    mpack = (norbs*(norbs + 1))/2
    numat = maxatoms
    nvar = 3*maxatoms
    n2elec = 2025*n9+100*n4+n1+2025*(n9*(n9-1))/2+450*n9*n4+45*n9*n1+&
     & 100*(n4*(n4-1))/2+10*n4*n1+ (n1*(n1-1))/2+10

    nmos = 12
    l123 = 1
    uhf = .true.
    call setup_mopac_arrays(1,2)
    allocate(geoa(3,maxatoms))
    na = 0
    nb = 0
    nc = 0
    pa = 0.d0
    pb = 0.d0
    atmass = 1.d0
    if (Index(contrl, "OLDFPC") == 0)then
  !
  ! Load in the modern (CODATA) fundamental constants
  !
      fpc_1 = fpcref(1, 1)
      fpc_2 = fpcref(1, 2)
      a0 = fpcref(1, 3)
      ev = fpcref(1, 4)
      fpc_5 = fpcref(1, 5)
      fpc_6 = fpcref(1, 6)
      fpc_7 = fpcref(1, 7)
      fpc_8 = fpcref(1, 8)
      fpc_9 = fpcref(1, 9)
      fpc_10 = fpcref(1, 10)
    else
  !
  ! Load in the old (CODATA) fundamental constants
  !
      fpc_1 = fpcref(2, 1)
      fpc_2 = fpcref(2, 2)
      a0 = fpcref(2, 3)
      ev = fpcref(2, 4)
      fpc_5 = fpcref(2, 5)
      fpc_6 = fpcref(2, 6)
      fpc_7 = fpcref(2, 7)
      fpc_8 = fpcref(2, 8)
      fpc_9 = fpcref(2, 9)
      fpc_10 = fpcref(2, 10)
    endif
    i = Index(contrl," POWER")
    if (i /= 0) power = Reada(contrl, i)
    do i = 1, n_methods
      methods(i) = (index(contrl, trim(methods_keys(i))//" ") /= 0)
    end do 
    do i = 1, n_methods
      if (methods(i)) exit
    end do
!
!  Define parent methods "method_PM6" and "method_PM7" for variants of these methods
!
    method_pm7 = (method_PM7 .or. method_PM7_ts .or. method_pm7_hh .or. method_pm7_minus)
    method_pm6 = (method_PM6 .or. method_pm6_dh2 .or. method_pm6_d3h4 .or. method_pm6_dh_plus .or. &
    & method_pm6_dh2x .or. method_pm6_d3h4x .or. method_pm6_d3 .or. method_pm6_d3_not_h4)
!
! Default method is pm6_org
!
    methods(18) = ( methods(18) .or. i > n_methods)
    tdump = 1.d8 ! (a long time)
    tleft=1.d6
!
!  Write out output banner
!
96 write (ifiles_8, "(1x,15('*****')//18x,'PARAMETRIZATION CALCULATION RESULTS',//1x,15('*****'))", iostat = i)
    if (i /= 0) then
      write(0,*)" Output file '"//trim(jobnam)//".out' is busy.  Correct the fault or kill this job"
      call sleep (10)
      go to 96
    end if
    idate = " "
    call fdate (idate)
    write (ifiles_8, "(' *',50x,A24)") idate
    write (ifiles_8, "(a19, 2x,i4,'  UNSIGNED AVE. ERROR')") idate(1:19), 0
    keywrd = contrl
    call split_keywords(keywrd)
    call parkey (contrl)
    contrl = trim(keywrd)
    write (ifiles_8, "(' *',/1X,15('*****'))")
    call switch
!
!
    penalty = 10000.d0  ! Contribution to SSQ = penalty*error**2
!
!
!
! Read in all data relating to parameters
!
    j = iw
    iw = ifiles_8
    call datin(ifiles_8)
    iw = j
    if (moperr) stop
    call getpar()
    if ((Index (contrl, " CHKPAR") /= 0) .and. numvar == 0) then
      write(ifiles_8,*)" No parameters therefore parameter ", &
      &" independence cannot be determined"
      call finish
    end if
    do i = 1,90
    if (f0sd_store(i) < 1.d-5) f0sd_store(i) = f0sd(i)
    if (g2sd_store(i) < 1.d-5) g2sd_store(i) = g2sd(i)
    end do
    do i = 57, 71
      if (zs(i) < 0.1d0) tore(i) = 3.d0
    end do
    call fractional_metal_ion
    call l_control(trim("ifiles_8=8"), len_trim("ifiles_8=8"), 1)   
    call calpar    
    if (Index (contrl, " CC") /= 0) then
    end if
    save_parameters = (Index (contrl, " NOSAVEP") == 0)
!
! Read in all data relating to reference data
!
    i = size(p)
    if (allocated(p)) deallocate(p)
    call datinp()
    maxci = 100
    text = trim(jobnam)//".F90" 
    j = iw
    iw = ifiles_8
    ! call create_parameters_for_PMx_C(text, "7") 
    iw = j
    allocate(p(i))
    call fractional_metal_ion
    large = (Index (contrl, " LARGE") /= 0)
!
!  Unconditionally, do not generate MOPAC log files
!
    inquire (unit=ilog, opened=opend)
    if (opend) then
      close (unit=ilog, status="DELETE")
    end if
    open (unit=ilog, file='fort.ilog', status="UNKNOWN", form="FORMATTED")
!
!  Do NOT generate normal MOPAC output, unless "LARGE" is present.
!
    if (large) then
      inquire (unit=iw, opened=opend)
      if (opend) then
        close (unit=iw, status="DELETE")
      end if
      i = Index (jobnam, " ") - 1
      inquire (unit=iarc, opened=opend)
      if (opend) close(iarc)
      open (unit=iw, file=jobnam(:len_trim(jobnam))//".arc", status="UNKNOWN")
      rewind (iw)
    else
      inquire (file=jobnam(:len_trim(jobnam))//".arc", exist = exists)
      if (exists) then
        open(unit = 10, file = jobnam(:len_trim(jobnam))//".arc", status='OLD', iostat=i)
        if (i == 0) close(10, status = 'delete', iostat=i)
      end if        
      open(newunit=iw,file='/dev/null',status='unknown',iostat=i)
      if (i /= 0) then
        open(newunit=iw,file='NUL',status='unknown',iostat=i)
        if (i /= 0) then
          write(ifiles_8, '(/10x, a)')" Could not open the NULL file"
          stop
        end if
      end if        
    end if     
    inquire (file=jobnam(:len_trim(jobnam))//".arc", exist = exists)    
  !***********************************************************************
  !
  !   Different functions within PARAM
  !
  !***********************************************************************
    if (Index (contrl, " CHKPAR") /= 0) then
    !
    ! Check the parameter set to see if it is well-defined
    !
      call direct(1)
      call chkpar
      write (ifiles_8, "(//20X,A)") " PARAM FINISHED"
      call finish
      stop
    end if
    if (Index (contrl, " SURVEY") /= 0) then
    !
    !   Generate publication-quality tables
    !
      call partab 
      call finish
    end if
    if (numvar < 1) then
    !
    ! Compute the error function, but do not optimize any parameters.
    !
      call direct (1)
      call finish
    end if
    if (Index (contrl, " CYCLES") /= 0) then
      maxcyc = Nint(Reada(contrl,Index (contrl, " CYCLES")))
    else
      maxcyc = 600
    end if
  !
  ! Optimize the parameters
  !
    fnsnew(1) = -1.d7
    do loop = 1, maxcyc
      call direct(loop)
 !     if (loop == 1) call trim_parameter_set
      call rapid0 (loop)
      call pparsav(save_parameters)
    !
    !  Calculate the predicted value of the new error function
    !
      do i = 1, nfns
        sum = 0.d0
        do j = 1, numvar
          sum = sum + xparamp(j) * diffns(j, i)
        end do
        fnsnew(i) = fns(i) - sum
      end do      
    end do
    call finish
 99 write(*,*)" Data file '",jobnam(:i),".dat' does not exist!"
    call finish
 98 write(*,*)" Data file '",jobnam(:i),".dat' is locked!"
    call finish
end program param
