import { supabase } from '../lib/supabase';
import type { Attendance, Notification, Parent, Payment, ReportCard, Result, Student } from '../types';

function client(){ if(!supabase) throw new Error('Supabase is not configured. Copy .env.example to .env and add your project URL and anonymous key.'); return supabase; }

export async function getSession(){ return client().auth.getSession(); }
export async function signIn(email:string,password:string){ return client().auth.signInWithPassword({email,password}); }
export async function signOut(){ return client().auth.signOut(); }
export async function resetPassword(email:string){ return client().auth.resetPasswordForEmail(email,{redirectTo:window.location.origin}); }

export async function getParentProfile():Promise<Parent>{
  const {data:{user},error:uerr}=await client().auth.getUser(); if(uerr||!user) throw new Error('Your session has expired. Please sign in again.');
  const {data,error}=await client().from('parents').select('id,user_id,school_id,parent_id_code,full_name,relationship,phone,email,photo_url').eq('user_id',user.id).maybeSingle();
  if(error) throw error; if(!data) throw new Error('No parent profile is linked to this account. Please contact the school office.'); return data as Parent;
}

export async function getChildren(parentId:string):Promise<Student[]>{
  const {data,error}=await client().from('parent_student_links').select('student_id, students!inner(id,school_id,student_id_number,admission_number,first_name,middle_name,last_name,dob,gender,photo_url,class_id,stream_id,house,status,classes(name),streams(name))').eq('parent_id',parentId).eq('is_active',true);
  if(error) throw error;
  return (data??[]).map((r:any)=>r.students).filter(Boolean) as Student[];
}

export async function getAttendance(studentId:string){ const {data,error}=await client().from('attendance').select('id,student_id,date,status,reason').eq('student_id',studentId).order('date',{ascending:false}); if(error)throw error; return (data??[]) as Attendance[]; }
export async function getPayments(studentId:string){ const {data,error}=await client().from('payments').select('id,student_id,receipt_number,amount_ugx,payment_date,payment_method,transaction_reference,academic_year,term,notes').eq('student_id',studentId).order('payment_date',{ascending:false}); if(error)throw error; return (data??[]) as Payment[]; }
export async function getResults(studentId:string){ const {data,error}=await client().from('results').select('id,exam_id,student_id,subject_id,marks_obtained,grade,achievement_level,remarks,exams!inner(id,name,exam_type,academic_year,term,start_date,end_date,is_published),subjects!inner(name,code)').eq('student_id',studentId).eq('is_published',true).eq('exams.is_published',true).order('created_at',{ascending:false}); if(error)throw error; return (data??[]) as unknown as Result[]; }
export async function getReportCards(studentId:string){ const {data,error}=await client().from('report_cards').select('*').eq('student_id',studentId).eq('is_published',true).order('academic_year',{ascending:false}).order('term',{ascending:false}); if(error)throw error; return (data??[]) as ReportCard[]; }
export async function getNotifications(schoolId:string){ const {data,error}=await client().from('notifications').select('id,title,message,target_role,sender_id,is_urgent,created_at').eq('school_id',schoolId).in('target_role',['All','Parents']).order('created_at',{ascending:false}).limit(50); if(error)throw error; return (data??[]) as Notification[]; }
export async function getSchool(schoolId:string){ const {data,error}=await client().from('schools').select('id,name,motto,logo_url,address,district,country,phone,alt_phone,email,currency,currency_code,timezone,current_academic_year,current_term').eq('id',schoolId).single(); if(error)throw error; return data; }
export async function getFeeStructure(student:Student){ if(!student.class_id) return 0; const {data,error}=await client().from('fee_structures').select('amount_ugx').eq('class_id',student.class_id).eq('academic_year',new Date().getFullYear().toString()).eq('is_active',true).eq('is_archived',false); if(error)throw error; return (data??[]).reduce((s:any,r:any)=>s+Number(r.amount_ugx||0),0); }
